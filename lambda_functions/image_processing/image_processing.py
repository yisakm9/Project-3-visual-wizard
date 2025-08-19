import boto3
import os

s3_client = boto3.client('s3')
rekognition_client = boto3.client('rekognition')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def lambda_handler(event, context):
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']

    response = rekognition_client.detect_labels(
        Image={
            'S3Object': {
                'Bucket': bucket,
                'Name': key
            }
        },
        MaxLabels=10
    )

    labels = [label['Name'] for label in response['Labels']]

    table.put_item(
        Item={
            'image_name': key,
            'labels': labels
        }
    )

    return {
        'statusCode': 200,
        'body': f"Image {key} processed successfully with labels: {labels}"
    }