import boto3
import json
import os
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client('s3')
rekognition_client = boto3.client('rekognition')
dynamodb = boto3.resource('dynamodb')

# Get the DynamoDB table name from an environment variable
LABELS_TABLE_NAME = os.environ.get('LABELS_TABLE_NAME')
if not LABELS_TABLE_NAME:
    raise ValueError("Missing environment variable: LABELS_TABLE_NAME")

table = dynamodb.Table(LABELS_TABLE_NAME)

def handler(event, context):
    """
    Lambda function handler triggered by an SQS event.
    Processes messages from SQS which contain S3 event notifications.
    """
    logger.info(f"Received event: {json.dumps(event)}")

    for record in event['Records']:
        try:
            # The actual S3 event is in the 'body' of the SQS message
            message_body = json.loads(record['body'])
            s3_record = message_body['Records'][0]
            
            bucket_name = s3_record['s3']['bucket']['name']
            object_key = s3_record['s3']['object']['key']

            logger.info(f"Processing image '{object_key}' from bucket '{bucket_name}'")

            # Call Rekognition to detect labels
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

            # Store each label in DynamoDB
            with table.batch_writer() as batch:
                for label in labels:
                    label_name = label['Name']
                    confidence = label['Confidence']
                    
                    batch.put_item(
                        Item={
                            'ImageKey': object_key,
                            'Label': label_name,
                            'Confidence': str(confidence)
                        }
                    )
            
            logger.info(f"Successfully stored labels for {object_key} in DynamoDB.")

        except Exception as e:
            logger.error(f"Error processing record: {e}")
            # Depending on the error, you might want to re-raise it to let SQS handle retries
            raise e
            
    return {
        'statusCode': 200,
        'body': json.dumps('Processing complete')
    }