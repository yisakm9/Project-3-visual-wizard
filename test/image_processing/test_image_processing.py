# test/image_processing/test_image_processing.py

import pytest
import boto3
from moto import mock_aws
import os
import urllib.parse

# Import the application module we intend to test
from src.image_processing import image_processing

@mock_aws
def test_successful_image_processing(monkeypatch):
    """
    Tests the main success path of the image_processing Lambda handler.
    - Mocks the necessary environment variables for the handler.
    - Mocks all required AWS services (S3, DynamoDB, Rekognition).
    - Simulates a realistic S3 event, including a URL-encoded object key.
    - Asserts that the handler returns a successful status code.
    - Asserts that the correct data is written to the mocked DynamoDB table.
    """
    # 1. ARRANGE: Set up the entire mocked environment

    # Set the environment variable that the handler will read
    table_name = "mock-visual-wizard-table"
    monkeypatch.setenv("DYNAMODB_TABLE_NAME", table_name)

    # --- Define and apply mocks for the boto3 clients used in the application code ---

    # Create a mock Rekognition client class that returns a predictable response
    class MockRekognitionClient:
        def detect_labels(self, Image, MaxLabels, MinConfidence):
            return {"Labels": [{"Name": "Dog", "Confidence": 99.0}, {"Name": "Pet", "Confidence": 98.0}]}

    # Use monkeypatch to replace the global client objects inside the image_processing module
    monkeypatch.setattr(image_processing, "rekognition_client", MockRekognitionClient())
    
    # This is the crucial part: create a moto-controlled DynamoDB resource
    # and patch it into the application module.
    mocked_dynamodb_resource = boto3.resource("dynamodb", region_name="us-east-1")
    monkeypatch.setattr(image_processing, "dynamodb", mocked_dynamodb_resource)

    # --- Set up the AWS resources within the mocked environment ---
    s3_client = boto3.client("s3", region_name="us-east-1")
    bucket_name = "test-bucket-123"
    original_image_key = "my dog photo.jpg"
    encoded_image_key = urllib.parse.quote_plus(original_image_key)

    s3_client.create_bucket(Bucket=bucket_name)
    
    # Create the mocked DynamoDB table with a schema that EXACTLY matches the Terraform definition
    table = mocked_dynamodb_resource.create_table(
        TableName=table_name,
        KeySchema=[
            {'AttributeName': 'ImageKey', 'KeyType': 'HASH'}
        ],
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

    # Create the simulated S3 trigger event
    s3_event = {
      "Records": [{"s3": {"bucket": {"name": bucket_name}, "object": {"key": encoded_image_key}}}]
    }

    # 2. ACT: Call the handler function with the mocked event and context
    result = image_processing.handler(s3_event, {})

    # 3. ASSERT: Verify the outcome
    
    # Check the handler's return value
    assert result['statusCode'] == 200
    assert "Successfully processed" in result['body']

    # Verify the contents of the mocked DynamoDB table
    ddb_items = table.scan()['Items']
    assert len(ddb_items) == 2  # One item for each detected label
    
    # Convert to a more easily searchable format
    items_by_label = {item['Label']: item for item in ddb_items}
    
    assert "Dog" in items_by_label
    assert "Pet" in items_by_label
    
    # Check one of the items in detail
    dog_item = items_by_label["Dog"]
    assert dog_item['ImageKey'] == original_image_key # Verify the key was decoded
    assert dog_item['AllLabels'] == ["Dog", "Pet"]