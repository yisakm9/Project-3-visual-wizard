# src/image_processing/image_processing.py

import os
import json
import boto3
import logging
import urllib.parse

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client('s3')
rekognition_client = boto.client('rekognition')
dynamodb = boto3.resource('dynamodb')

# Get DynamoDB table name from environment variables
DYNAMODB_TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME')
if not DYNAMODB_TABLE_NAME:
    raise ValueError("DYNAMODB_TABLE_NAME environment variable not set.")
    
table = dynamodb.Table(DYNAMODB_TABLE_NAME)

def handler(event, context):
    """
    Lambda function handler triggered by an SQS event.
    Processes messages from SQS which contain S3 object creation notifications.
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    for record in event['Records']:
        try:
            # The actual S3 event is nested inside the SQS message body
            body = json.loads(record['body'])
            
            # --- FIX STARTS HERE ---
            # Check if this is a test event from the S3 console and skip it
            if 'Event' in body and body['Event'] == 's3:TestEvent':
                logger.warning("This is a test event from S3. Skipping processing.")
                continue # Skips to the next message in the batch

            # For a real event, the S3 data is in the 'Records' key
            if 'Records' not in body:
                logger.error(f"SQS message body does not contain 'Records' key: {body}")
                continue
            # --- FIX ENDS HERE ---

            s3_record = body['Records'][0]
            
            # Extract bucket name and object key from the S3 event
            bucket_name = s3_record['s3']['bucket']['name']
            # The object key can have special characters, so we need to unquote it
            object_key = urllib.parse.unquote_plus(s3_record['s3']['object']['key'])

            logger.info(f"Processing image '{object_key}' from bucket '{bucket_name}'")

            # 1. Call Amazon Rekognition to detect labels
            response = rekognition_client.detect_labels(
                Image={
                    'S3Object': {
                        'Bucket': bucket_name,
                        'Name': object_key
                    }
                },
                MaxLabels=10,
                MinConfidence=90
            )
            
            labels = [label['Name'] for label in response['Labels']]
            logger.info(f"Detected labels: {labels}")

            # 2. Store the labels in DynamoDB
            table.put_item(
                Item={
                    'ImageKey': object_key,
                    'Labels': labels,
                    'Bucket': bucket_name
                }
            )
            logger.info(f"Successfully stored labels for '{object_key}' in DynamoDB table '{DYNAMODB_TABLE_NAME}'")

        except Exception as e:
            logger.error(f"Error processing record: {e}")
            # Re-raise the exception to allow SQS to handle the message retry/dead-letter queue logic
            raise e
            
    return {
        'statusCode': 200,
        'body': json.dumps('Processing complete')
    }