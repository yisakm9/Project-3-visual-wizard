# test/image_processing/test_image_processing.py

import pytest
import boto3
from moto import mock_aws
import os
import urllib.parse

# Import the handler function we want to test
from src.image_processing.image_processing import handler

@mock_aws
def test_successful_image_processing(monkeypatch):
    """
    Tests the main success path of the image_processing Lambda.
    - Mocks the necessary environment variables.
    - Mocks AWS services (S3, DynamoDB).
    - Simulates an S3 event with a URL-encoded key.
    - Asserts that the function returns a successful status code.
    """
    # 1. ARRANGE: Set up the mocked environment
    
    # Use pytest's monkeypatch to set environment variables for this test only
    monkeypatch.setenv("DYNAMODB_TABLE_NAME", "mock-visual-wizard-table")

    # Set up mocked AWS resources
    s3_client = boto3.client("s3", region_name="us-east-1")
    dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
    
    bucket_name = "test-bucket-123"
    # Simulate a filename with a space, which S3 will URL-encode
    original_image_key = "my test image.jpg"
    encoded_image_key = urllib.parse.quote_plus(original_image_key) # "my+test+image.jpg"
    
    table_name = os.environ.get("DYNAMODB_TABLE_NAME")

    # Create the mocked bucket and table
    s3_client.create_bucket(Bucket=bucket_name)
    table = dynamodb.create_table(
        TableName=table_name,
        KeySchema=[{'AttributeName': 'ImageKey', 'KeyType': 'HASH'}, {'AttributeName': 'Label', 'KeyType': 'RANGE'}],
        AttributeDefinitions=[
            {'AttributeName': 'ImageKey', 'AttributeType': 'S'},
            {'AttributeName': 'Label', 'AttributeType': 'S'}
        ],
        ProvisionedThroughput={'ReadCapacityUnits': 1, 'WriteCapacityUnits': 1}
    )

    # Create a sample S3 event payload with the encoded key
    s3_event = {
      "Records": [{"s3": {"bucket": {"name": bucket_name}, "object": {"key": encoded_image_key}}}]
    }

    # Moto doesn't fully support mocking Rekognition's detect_labels with S3 objects.
    # So, we will mock the client's response directly.
    class MockRekognition:
        def detect_labels(self, Image, MaxLabels, MinConfidence):
            return {
                "Labels": [
                    {"Name": "Canine", "Confidence": 99.5},
                    {"Name": "Dog", "Confidence": 99.5}
                ]
            }
    
    monkeypatch.setattr(boto3, "client", lambda service_name: MockRekognition() if service_name == 'rekognition' else boto3.client(service_name))

    # 2. ACT: Call the handler function with the simulated event
    result = handler(s3_event, {})

    # 3. ASSERT: Check the results
    assert result['statusCode'] == 200
    assert "Successfully processed" in result['body']

    # Verify that the items were written to DynamoDB correctly
    ddb_items = table.scan()['Items']
    assert len(ddb_items) == 2
    assert ddb_items[0]['ImageKey'] == original_image_key # Should be the DECODED key
    assert ddb_items[0]['Label'] in ["Canine", "Dog"]