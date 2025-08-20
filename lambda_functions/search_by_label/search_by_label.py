import boto3
import os
import json

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def lambda_handler(event, context):
    # Use .get() to safely access queryStringParameters.
    # It returns None if the key doesn't exist, preventing a crash.
    params = event.get('queryStringParameters')

    # Check if params exist and if 'label' is in them.
    if not params or 'label' not in params:
        return {
            'statusCode': 400, # 400 means "Bad Request"
            'body': json.dumps({'error': "Query string parameter 'label' is missing."})
        }

    label = params['label']

    response = table.scan(
        FilterExpression='contains(labels, :label)',
        ExpressionAttributeValues={
            ':label': label
        }
    )

    items = response.get('Items', [])

    return {
        'statusCode': 200,
        'body': json.dumps(items)
    }