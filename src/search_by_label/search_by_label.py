import boto3
import os
import json
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
    raise ValueError("Missing environment variables for DynamoDB table/index name.")
table = dynamodb.Table(TABLE_NAME)

def handler(event, context):
    """
    This function is triggered by API Gateway. It searches DynamoDB for images
    matching a given label.
    """
    logger.info("Received event: %s", event)

    # Get the search label from the query string parameters
    query_params = event.get('queryStringParameters', {})
    if not query_params or 'label' not in query_params:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': "Query parameter 'label' is required."})
        }
    
    label_to_search = query_params['label']
    logger.info("Searching for label: '%s'", label_to_search)

    try:
        # Query the Global Secondary Index (GSI)
        response = table.query(
            IndexName=INDEX_NAME,
            KeyConditionExpression=Key('Label').eq(label_to_search)
        )

        items = response.get('Items', [])
        
        # We only need the unique image keys
        image_keys = list(set([item['ImageKey'] for item in items]))
        
        logger.info("Found %d matching images.", len(image_keys))

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({'images': image_keys})
        }

    except Exception as e:
        logger.error("Error querying DynamoDB: %s", str(e))
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error.'})
        }