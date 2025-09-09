# src/image_processing/image_processing.py

import boto3
import os
import logging
import urllib.parse

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Get table name from environment variable - this is safe to keep global
TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME')

def handler(event, context):
    """
    This function is triggered by an S3 event and processes the uploaded image.
    """
    # --- FINAL FIX: Initialize all boto3 clients and resources inside the handler ---
    rekognition_client = boto3.client('rekognition')
    dynamodb = boto3.resource('dynamodb')
    
    if not TABLE_NAME:
        raise ValueError("Environment variable DYNAMODB_TABLE_NAME is not set.")
    table = dynamodb.Table(TABLE_NAME)

    logger.info("Received event: %s", event)

    # ... (the rest of the handler logic remains exactly the same) ...
    bucket_name = event['Records'][0]['s3']['bucket']['name']
    encoded_image_key = event['Records'][0]['s3']['object']['key']
    image_key = urllib.parse.unquote_plus(encoded_image_key)
    
    logger.info("Processing decoded image key '%s' from bucket '%s'.", image_key, bucket_name)

    try:
        response = rekognition_client.detect_labels(
            Image={'S3Object': {'Bucket': bucket_name, 'Name': image_key}},
            MaxLabels=10,
            MinConfidence=80
        )
        labels = [label['Name'] for label in response.get('Labels', [])]
        logger.info("Detected labels: %s", labels)

        if not labels:
            logger.warning("No labels detected for image %s.", image_key)
            return {'statusCode': 200, 'body': f'No labels found for {image_key}'}

        with table.batch_writer() as batch:
            for label in labels:
                batch.put_item(
                    Item={
                        'ImageKey': image_key,
                        'Label': label,
                        'AllLabels': labels
                    }
                )

        logger.info("Successfully stored labels for image %s in DynamoDB.", image_key)
        return {
            'statusCode': 200,
            'body': f'Successfully processed image {image_key} and found labels: {labels}'
        }
    except Exception as e:
        logger.error("Error processing image %s: %s", image_key, str(e))
        raise e