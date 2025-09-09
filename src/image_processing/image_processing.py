# src/image_processing/image_processing.py

import os
import boto3
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client('s3')
rekognition_client = boto3.client('rekognition')
dynamodb = boto3.resource('dynamodb')

# Get table name from environment variables
TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME')
if not TABLE_NAME:
    raise ValueError("Missing environment variable: DYNAMODB_TABLE_NAME")

table = dynamodb.Table(TABLE_NAME)

def handler(event, context):
    """
    Lambda handler function triggered by an S3 event.
    - Processes the uploaded image.
    - Detects labels using Amazon Rekognition.
    - Stores the image key and labels in a DynamoDB table.
    """
    logger.info("Received event: %s", event)

    # Get the bucket and key from the S3 event record
    try:
        bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']
    except (KeyError, IndexError) as e:
        logger.error("Failed to parse S3 event: %s", e)
        return {'statusCode': 400, 'body': 'Invalid S3 event format'}

    logger.info("Processing image '%s' from bucket '%s'", key, bucket)

    try:
        # Call Rekognition to detect labels
        response = rekognition_client.detect_labels(
            Image={'S3Object': {'Bucket': bucket, 'Name': key}},
            MaxLabels=10,
            MinConfidence=80
        )

        labels = [label['Name'].lower() for label in response.get('Labels', [])]
        logger.info("Detected labels: %s", labels)

        if not labels:
            logger.warning("No labels detected for image '%s'", key)
            return {'statusCode': 200, 'body': 'No labels detected'}

        # Store the image key and labels in DynamoDB
        for label in labels:
            table.put_item(
                Item={
                    'image_key': key,
                    'label': label
                }
            )
        
        logger.info("Successfully stored labels for '%s' in DynamoDB", key)
        return {'statusCode': 200, 'body': 'Image processed successfully'}

    except Exception as e:
        logger.error("Error processing image '%s': %s", key, e)
        # It's good practice to re-raise the exception to allow for retries
        raise e