import boto3
import json
import os
import logging
from boto3.dynamodb.conditions import Key

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')

LABELS_TABLE_NAME = os.environ.get('LABELS_TABLE_NAME')
if not LABELS_TABLE_NAME:
    raise ValueError("Missing environment variable: LABELS_TABLE_NAME")
    
GSI_NAME = os.environ.get('GSI_NAME')
if not GSI_NAME:
    raise ValueError("Missing environment variable: GSI_NAME")

table = dynamodb.Table(LABELS_TABLE_NAME)

def handler(event, context):
    """
    Lambda function handler triggered by API Gateway to search for images by label.
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    query_params = event.get('queryStringParameters', {})
    if not query_params or 'label' not in query_params:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Query parameter "label" is required.'})
        }
        
    label_to_search = query_params['label']
    
    try:
        response = table.query(
            IndexName=GSI_NAME,
            KeyConditionExpression=Key('Label').eq(label_to_search)
        )
        
        items = response.get('Items', [])
        image_keys = [item['ImageKey'] for item in items]
        
        logger.info(f"Found {len(image_keys)} images for label '{label_to_search}'")
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({
                'label': label_to_search,
                'images': image_keys
            })
        }
        
    except Exception as e:
        logger.error(f"Error querying DynamoDB: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error while searching.'})
        }