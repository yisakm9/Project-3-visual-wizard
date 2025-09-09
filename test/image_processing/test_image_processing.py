# test/image_processing/test_image_processing.py

import pytest
import boto3
from moto import mock_aws
import os
import urllib.parse
# Import patch and the special DEFAULT object
from unittest.mock import patch, DEFAULT

from src.image_processing import image_processing

@mock_aws
def test_successful_image_processing(monkeypatch):
    """
    Tests the main success path of the image_processing Lambda handler.
    """
    # 1. ARRANGE: Set up the mocked environment
    table_name = "mock-visual-wizard-table"
    monkeypatch.setenv("DYNAMODB_TABLE_NAME", table_name)
    
    # We use 'patch' to intercept calls to boto3.client.
    with patch('boto3.client') as mock_boto_client:
        
        class MockRekognition:
            def detect_labels(self, Image, MaxLabels, MinConfidence):
                return {"Labels": [{"Name": "Dog", "Confidence": 99.0}, {"Name": "Pet", "Confidence": 98.0}]}

        # --- THIS IS THE CORRECTED SIDE EFFECT ---
        # This function will be called every time boto3.client is called.
        def boto_client_side_effect(service_name, *args, **kwargs):
            if service_name == 'rekognition':
                # If the code asks for a Rekognition client, return our custom mock.
                return MockRekognition()
            # For any other service (like 's3'), return DEFAULT.
            # This tells the patch to call the ORIGINAL boto3.client function.
            return DEFAULT

        mock_boto_client.side_effect = boto_client_side_effect

        # Now, when boto3.client("s3",...) is called, the side effect will return DEFAULT,
        # which then calls the original boto3.client. Moto's @mock_aws decorator
        # intercepts that *original* call and returns a mocked S3 client.
        s3_client = boto3.client("s3", region_name="us-east-1")
        dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
        
        bucket_name = "test-bucket-123"
        original_image_key = "my dog photo.jpg"
        encoded_image_key = urllib.parse.quote_plus(original_image_key)

        s3_client.create_bucket(Bucket=bucket_name)
        table = dynamodb.create_table(
            TableName=table_name,
            KeySchema=[{'AttributeName': 'ImageKey', 'KeyType': 'HASH'}],
            AttributeDefinitions=[
                {'AttributeName': 'ImageKey', 'AttributeType': 'S'},
                {'AttributeName': 'Label', 'AttributeType': 'S'}
            ],
            GlobalSecondaryIndexes=[{
                'IndexName': 'LabelsIndex',
                'KeySchema': [{'AttributeName': 'Label', 'KeyType': 'HASH'}],
                'Projection': {'ProjectionType': 'ALL'},
                'ProvisionedThroughput': {'ReadCapacityUnits': 1, 'WriteCapacityUnits': 1}
            }],
            ProvisionedThroughput={'ReadCapacityUnits': 1, 'WriteCapacityUnits': 1}
        )

        s3_event = {
          "Records": [{"s3": {"bucket": {"name": bucket_name}, "object": {"key": encoded_image_key}}}]
        }

        # 2. ACT: Call the handler.
        result = image_processing.handler(s3_event, {})

    # 3. ASSERT: Verify the outcome
    assert result['statusCode'] == 200
    assert "Successfully processed" in result['body']

    ddb_items = table.scan()['Items']
    assert len(ddb_items) == 2
    assert ddb_items[0]['ImageKey'] == original_image_key