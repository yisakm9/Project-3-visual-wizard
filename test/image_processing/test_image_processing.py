# test/image_processing/test_image_processing.py

import pytest
import boto3
from moto import mock_aws
import os
import urllib.parse

from src.image_processing import image_processing

@mock_aws
def test_successful_image_processing(monkeypatch):
    """
    Tests the main success path of the image_processing Lambda.
    """
    # 1. ARRANGE: Set up the mocked environment
    table_name = "mock-visual-wizard-table"
    monkeypatch.setenv("DYNAMODB_TABLE_NAME", table_name)

    # Mock the specific clients within the module we are testing
    class MockRekognitionClient:
        def detect_labels(self, Image, MaxLabels, MinConfidence):
            return {"Labels": [{"Name": "Dog", "Confidence": 99.0}, {"Name": "Pet", "Confidence": 98.0}]}

    monkeypatch.setattr(image_processing, "rekognition_client", MockRekognitionClient())
    
    mocked_dynamodb_resource = boto3.resource("dynamodb", region_name="us-east-1")
    monkeypatch.setattr(image_processing, "dynamodb", mocked_dynamodb_resource)

    s3_client = boto3.client("s3", region_name="us-east-1")
    bucket_name = "test-bucket-123"
    original_image_key = "my dog photo.jpg"
    encoded_image_key = urllib.parse.quote_plus(original_image_key)

    s3_client.create_bucket(Bucket=bucket_name)

    # --- THIS IS THE CORRECTED SCHEMA ---
    # It now exactly matches the schema in modules/dynamodb/main.tf
    table = mocked_dynamodb_resource.create_table(
        TableName=table_name,
        KeySchema=[
            {'AttributeName': 'ImageKey', 'KeyType': 'HASH'}
            # The 'Label' is part of a GSI, not the primary key, so it's removed from here.
        ],
        AttributeDefinitions=[
            {'AttributeName': 'ImageKey', 'AttributeType': 'S'},
            {'AttributeName': 'Label', 'AttributeType': 'S'} # Still need to define the GSI attribute
        ],
        GlobalSecondaryIndexes=[
            {
                'IndexName': 'LabelsIndex',
                'KeySchema': [{'AttributeName': 'Label', 'KeyType': 'HASH'}],
                'Projection': {'ProjectionType': 'ALL'},
                'ProvisionedThroughput': {'ReadCapacityUnits': 1, 'WriteCapacityUnits': 1}
            }
        ],
        ProvisionedThroughput={'ReadCapacityUnits': 1, 'WriteCapacityUnits': 1}
    )

    s3_event = {
      "Records": [{"s3": {"bucket": {"name": bucket_name}, "object": {"key": encoded_image_key}}}]
    }

    # 2. ACT: Call the handler function
    result = image_processing.handler(s3_event, {})

    # 3. ASSERT: Check the results
    assert result['statusCode'] == 200
    assert "Successfully processed" in result['body']

    # Verify that the correct items were written to the mocked DynamoDB table
    ddb_items = table.scan()['Items']
    assert len(ddb_items) == 2
    item1 = ddb_items[0]
    assert item1['ImageKey'] == original_image_key
    assert item1['Label'] in ["Dog", "Pet"]