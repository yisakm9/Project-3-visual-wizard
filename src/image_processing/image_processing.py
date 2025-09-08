import boto3
import os
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
    This function is triggered by an S3 event. It uses Amazon Rekognition
    to detect labels in the uploaded image and stores them in DynamoDB.
    """
    logger.info("Received event: %s", event)

    # Get the bucket and key from the S3 event
    bucket_name = event['Records'][0]['s3']['bucket']['name']
    image_key = event['Records'][0]['s3']['object']['key']

    logger.info("Processing image '%s' from bucket '%s'.", image_key, bucket_name)

    try:
        # Call Rekognition to detect labels
        response = rekognition_client.detect_labels(
            Image={
                'S3Object': {
                    'Bucket': bucket_name,
                    'Name': image_key
                }
            },
            MaxLabels=10,
            MinConfidence=80
        )

        labels = [label['Name'] for label in response.get('Labels', [])]
        logger.info("Detected labels: %s", labels)

        if not labels:
            logger.warning("No labels detected with sufficient confidence for image %s.", image_key)
            return

        # Store each label as a separate item in DynamoDB for the GSI to work
        with table.batch_writer() as batch:
            for label in labels:
                batch.put_item(
                    Item={
                        'ImageKey': image_key,
                        'Label': label,
                        'AllLabels': labels # Store the full list for context
                    }
                )

        logger.info("Successfully stored labels for image %s in DynamoDB.", image_key)

        return {
            'statusCode': 200,
            'body': f'Successfully processed image {image_key} and found labels: {labels}'
        }

    except Exception as e:
        logger.error("Error processing image %s: %s", image_key, str(e))
        # Depending on requirements, you could add this message to a dead-letter queue (DLQ)
        raise e