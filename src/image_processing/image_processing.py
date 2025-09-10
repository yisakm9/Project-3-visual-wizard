import boto3
import json
import os
import logging
import urllib.parse

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
rekognition_client = boto3.client('rekognition')
dynamodb = boto3.resource('dynamodb')

# Get configuration from environment variables
LABELS_TABLE_NAME = os.environ.get('LABELS_TABLE_NAME')
if not LABELS_TABLE_NAME:
    raise ValueError("Missing environment variable: LABELS_TABLE_NAME")

table = dynamodb.Table(LABELS_TABLE_NAME)

def handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")

    for record in event['Records']:
        try:
            message_body = json.loads(record['body'])

            # --- THIS IS THE FIX ---
            # Check if this is a real S3 event and not a test event
            if 'Records' not in message_body:
                logger.info("Skipping non-S3 event or S3 Test Event.")
                continue

            s3_record = message_body['Records'][0]
            
            bucket_name = s3_record['s3']['bucket']['name']
            object_key_encoded = s3_record['s3']['object']['key']
            object_key = urllib.parse.unquote_plus(object_key_encoded)

            logger.info(f"Processing image '{object_key}' from bucket '{bucket_name}'")

            response = rekognition_client.detect_labels(
                Image={'S3Object': {'Bucket': bucket_name, 'Name': object_key}},
                MaxLabels=10,
                MinConfidence=90
            )

            labels = response.get('Labels', [])
            if not labels:
                logger.warning(f"No labels detected with >90% confidence for {object_key}")
                continue

            logger.info(f"Detected labels: {[label['Name'] for label in labels]}")

            with table.batch_writer() as batch:
                for label in labels:
                    label_name = label['Name']
                    confidence = label['Confidence']
                    batch.put_item(
                        Item={
                            'ImageKey': object_key,
                            'Label': label_name,
                            'Confidence': str(round(float(confidence), 2))
                        }
                    )
            
            logger.info(f"Successfully stored {len(labels)} labels for '{object_key}' in DynamoDB.")

        except Exception as e:
            logger.error(f"Error processing SQS record: {e}")
            raise e
            
    return {
        'statusCode': 200,
        'body': json.dumps('Processing complete for all messages.')
    }