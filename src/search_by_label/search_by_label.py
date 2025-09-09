import boto3
import json
import os
import logging

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')

# Get table name from environment variable
TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME')
if not TABLE_NAME:
    raise ValueError("DYNAMODB_TABLE_NAME environment variable not set.")
    
table = dynamodb.Table(TABLE_NAME)

def handler(event, context):
    """
    Lambda function to search for images by a label in DynamoDB.
    The label is passed as a query string parameter.
    """
    logger.info(f"Received event: {json.dumps(event)}")

    # Get the label from the query string parameters
    query_params = event.get('queryStringParameters', {})
    label_to_find = query_params.get('label') if query_params else None

    if not label_to_find:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Query parameter "label" is required.'})
        }

    logger.info(f"Searching for images with label: '{label_to_find}'")

    try:
        # A scan operation is expensive. For production, use a GSI.
        response = table.scan(
            FilterExpression='contains(labels, :label)',
            ExpressionAttributeValues={
                ':label': label_to_find
            }
        )
        
        items = response.get('Items', [])
        logger.info(f"Found {len(items)} items.")

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps(items)
        }

    except Exception as e:
        logger.error(f"Error scanning DynamoDB table: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error.'})
        }