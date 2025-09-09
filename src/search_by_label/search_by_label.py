# src/search_by_label/search_by_label.py

import os
import json
import boto3
from boto3.dynamodb.conditions import Attr
import logging

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
DYNAMODB_TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME')
if not DYNAMODB_TABLE_NAME:
    raise ValueError("DYNAMODB_TABLE_NAME environment variable not set.")
table = dynamodb.Table(DYNAMODB_TABLE_NAME)

def handler(event, context):
    """
    Lambda function handler triggered by API Gateway to search for images by a label.
    """
    logger.info(f"Received event: {json.dumps(event)}")

    # API Gateway passes query string parameters in this key
    params = event.get('queryStringParameters')

    if not params or 'label' not in params:
        return {
            'statusCode': 400,
            'headers': { "Content-Type": "application/json" },
            'body': json.dumps({'error': "Query string parameter 'label' is required."})
        }
    
    search_label = params['label']
    logger.info(f"Searching for label: '{search_label}'")

    try:
        # Scan the table for items where the 'Labels' list contains the search label
        response = table.scan(
            FilterExpression=Attr('Labels').contains(search_label)
        )
        
        items = response.get('Items', [])
        image_keys = [item['ImageKey'] for item in items]
        
        return {
            'statusCode': 200,
            'headers': { "Content-Type": "application/json" },
            'body': json.dumps({'label': search_label, 'images': image_keys})
        }

    except Exception as e:
        logger.error(f"Error scanning DynamoDB table: {e}")
        return {
            'statusCode': 500,
            'headers': { "Content-Type": "application/json" },
            'body': json.dumps({'error': 'Internal server error.'})
        }