import boto3
import json
import os
import logging

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3 = boto3.client('s3')
rekognition = boto3.client('rekognition')
dynamodb = boto3.resource('dynamodb')

# Get table name from environment variable
TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME')
if not TABLE_NAME:
    raise ValueError("DYNAMODB_TABLE_NAME environment variable not set.")
    
table = dynamodb.Table(TABLE_NAME)

def handler(event, context):
    """
    Lambda function handler to process SQS messages about S3 object creation.
    """
    logger.info(f"Received event: {json.dumps(event)}")

    for record in event.get('Records', []):
        try:
            # Parse the S3 event notification from the SQS message body
            sqs_body = json.loads(record.get('body', '{}'))
            s3_record = sqs_body.get('Records', [{}])[0]

            bucket_name = s3_record.get('s3', {}).get('bucket', {}).get('name')
            image_key = s3_record.get('s3', {}).get('object', {}).get('key')

            if not bucket_name or not image_key:
                logger.error("Could not extract bucket name or image key from the record.")
                continue

            logger.info(f"Processing image '{image_key}' from bucket '{bucket_name}'.")

            # Call Rekognition to detect labels
            response = rekognition.detect_labels(
                Image={
                    'S3Object': {
                        'Bucket': bucket_name,
                        'Name': image_key
                    }
                },
                MaxLabels=10,
                MinConfidence=90
            )

            labels = [label['Name'] for label in response.get('Labels', [])]
            logger.info(f"Detected labels: {labels}")

            # Store the labels in DynamoDB
            table.put_item(
                Item={
                    'image_key': image_key,
                    'labels': labels,
                    'bucket': bucket_name
                }
            )
            logger.info(f"Successfully stored labels for '{image_key}' in DynamoDB.")

        except Exception as e:
            logger.error(f"Error processing record: {e}")
            # Depending on the error, you might want to re-raise it to prevent the message from being deleted from the queue
            raise e

    return {
        'statusCode': 200,
        'body': json.dumps('Processing complete.')
    }