# src/search_by_label/search_by_label.py

import os
import json
import boto3
import logging
from boto3.dynamodb.conditions import Key

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')

# Get table and index names from environment variables
TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME')
INDEX_NAME = os.environ.get('DYNAMODB_INDEX_NAME')

if not TABLE_NAME or not INDEX_NAME:
    raise ValueError("Missing one or more environment variables: DYNAMODB_TABLE_NAME, DYNAMODB_INDEX_NAME")

table = dynamodb.Table(TABLE_NAME)

def handler(event, context):
    """
    Lambda handler function triggered by API Gateway.
    - Expects a 'label' query string parameter.
    - Queries the DynamoDB GSI to find matching images.
    - Returns a JSON list of image keys.
    """
    logger.info("Received event: %s", event)

    # Get the search label from query string parameters
    query_params = event.get('queryStringParameters', {})
    if not query_params or 'label' not in query_params:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': "Missing required query parameter: 'label'"})
        }

    search_label = query_params['label'].lower()
    logger.info("Searching for label: '%s'", search_label)

    try:
        # Query the GSI
        response = table.query(
            IndexName=INDEX_NAME,
            KeyConditionExpression=Key('label').eq(search_label)
        )

        items = response.get('Items', [])
        image_keys = [item['image_key'] for item in items]
        
        logger.info("Found %d images for label '%s'", len(image_keys), search_label)

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({'images': image_keys})
        }

    except Exception as e:
        logger.error("Error querying DynamoDB: %s", e)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }