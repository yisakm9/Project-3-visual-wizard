import boto3
import os
import json

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def lambda_handler(event, context):
    label = event['queryStringParameters']['label']

    response = table.scan(
        FilterExpression='contains(labels, :label)',
        ExpressionAttributeValues={
            ':label': label
        }
    )

    items = response['Items']

    return {
        'statusCode': 200,
        'body': json.dumps(items)
    }