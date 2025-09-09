# test/image_processing/test_image_processing.py

import pytest
import boto3
from moto import mock_aws
import os
import urllib.parse

# Import the handler from the source file
from src.image_processing import image_processing

@mock_aws
def test_successful_image_processing(monkeypatch):
    """
    Tests the main success path of the image_processing Lambda.
    - Mocks the necessary environment variables.
    - Mocks AWS services (S3, DynamoDB, Rekognition).
    - Simulates an S3 event with a URL-encoded key.
    - Asserts that the function returns a successful status code and writes to DynamoDB.
    """
    # 1. ARRANGE: Set up the mocked environment
    
    # Set environment variables for the handler
    table_name = "mock-visual-wizard-table"
    monkeypatch.setenv("DYNAMODB_TABLE_NAME", table_name)

    # --- THIS IS THE CORRECTED MOCKING STRATEGY ---
    
    # Mock the specific clients within the module we are testing
    class MockRekognitionClient:
        def detect_labels(self, Image, MaxLabels, MinConfidence):
            return {"Labels": [{"Name": "Dog", "Confidence": 99.0}, {"Name": "Pet", "Confidence": 98.0}]}

    # Patch the rekognition_client object inside the image_processing module
    monkeypatch.setattr(image_processing, "rekognition_client", MockRekognitionClient())
    
    # Patch the dynamodb resource to ensure it uses the moto-controlled session
    mocked_dynamodb_resource = boto3.resource("dynamodb", region_name="us-east-1")
    monkeypatch.setattr(image_processing, "dynamodb", mocked_dynamodb_resource)

    # --- Set up the rest of the mocked AWS resources ---
    s3_client = boto3.client("s3", region_name="us-east-1")
    bucket_name = "test-bucket-123"
    original_image_key = "my dog photo.jpg"
    encoded_image_key = urllib.parse.quote_plus(original_image_key)

    # Create the mocked bucket and table using the moto-controlled client
    s3_client.create_bucket(Bucket=bucket_name)
    table = mocked_dynamodb_resource.create_table(
        TableName=table_name,
        KeySchema=[{'AttributeName': 'ImageKey', 'KeyType': 'HASH'}, {'AttributeName': 'Label', 'KeyType': 'RANGE'}],
        AttributeDefinitions=[
            {'AttributeName': 'ImageKey', 'AttributeType': 'S'},
            {'AttributeName': 'Label', 'AttributeType': 'S'}
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
    
    # Check the first item
    item1 = ddb_items[0]
    assert item1['ImageKey'] == original_image_key # Assert the key was decoded
    assert item1['Label'] in ["Dog", "Pet"]
    assert item1['AllLabels'] == ["Dog", "Pet"]