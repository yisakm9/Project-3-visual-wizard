import boto3
import json
import os
import logging
import urllib.parse

# Configure logging to show up in CloudWatch
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients outside of the handler for performance
rekognition_client = boto3.client('rekognition')
dynamodb = boto3.resource('dynamodb')

# Get configuration from environment variables set by Terraform
LABELS_TABLE_NAME = os.environ.get('LABELS_TABLE_NAME')
if not LABELS_TABLE_NAME:
    raise ValueError("Missing environment variable: LABELS_TABLE_NAME")

table = dynamodb.Table(LABELS_TABLE_NAME)

def handler(event, context):
    """
    Lambda function handler triggered by an SQS event.
    Processes messages from SQS which contain S3 event notifications,
    detects labels in the uploaded image using Rekognition, and
    stores the results in DynamoDB.
    """
    logger.info(f"Received event: {json.dumps(event)}")

    for record in event['Records']:
        # Use a try/except block to handle potential errors for each message
        try:
            # The S3 event notification is nested inside the SQS message body
            message_body = json.loads(record['body'])
            s3_record = message_body['Records'][0]
            
            bucket_name = s3_record['s3']['bucket']['name']
            object_key_encoded = s3_record['s3']['object']['key']

            # FIX: URL-decode the object key to handle spaces and special characters
            object_key = urllib.parse.unquote_plus(object_key_encoded)

            logger.info(f"Processing image '{object_key}' from bucket '{bucket_name}'")

            # Call Rekognition to detect labels in the S3 object
            response = rekognition_client.detect_labels(
                Image={'S3Object': {'Bucket': bucket_name, 'Name': object_key}},
                MaxLabels=10,
                MinConfidence=90
            )

            labels = response.get('Labels', [])
            if not labels:
                logger.warning(f"No labels detected with >90% confidence for {object_key}")
                continue

            detected_labels = [label['Name'] for label in labels]
            logger.info(f"Detected labels: {detected_labels}")

            # Use a batch writer for efficient writes to DynamoDB
            with table.batch_writer() as batch:
                for label in labels:
                    label_name = label['Name']
                    confidence = label['Confidence']
                    
                    # Create a unique item for each label associated with the image
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
            # Re-raise the exception. This tells SQS that the message processing
            # failed, and it will be retried based on the queue's configuration.
            raise e
            
    return {
        'statusCode': 200,
        'body': json.dumps('Processing complete for all messages.')
    }