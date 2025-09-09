# test/image_processing/test_image_processing.py

import pytest
import boto3
from moto import mock_aws
import os
import urllib.parse
from unittest.mock import patch

# Import the application module to be tested
from src.image_processing import image_processing

@mock_aws
def test_successful_image_processing(monkeypatch):
    """
    Tests the main success path of the image_processing Lambda handler.
    """
    # 1. ARRANGE: Set up the mocked environment
    table_name = "mock-visual-wizard-table"
    monkeypatch.setenv("DYNAMODB_TABLE_NAME", table_name)
    
    # Set up AWS resources within the @mock_aws context
    s3_client = boto3.client("s3", region_name="us-east-1")
    dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
    
    bucket_name = "test-bucket-123"
    original_image_key = "my dog photo.jpg"
    encoded_image_key = urllib.parse.quote_plus(original_image_key)

    s3_client.create_bucket(Bucket=bucket_name)
    
    # Create the mocked DynamoDB table that we want our application to use
    mock_table = dynamodb.create_table(
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

    # --- THIS IS THE FINAL, CORRECTED MOCKING STRATEGY ---
    
    # We will patch the specific objects within the application module's namespace
    with patch.object(image_processing, 'rekognition_client') as mock_rek_client, \
         patch.object(image_processing.dynamodb, 'Table') as mock_dynamo_table:

        # Configure the mock return values
        mock_rek_client.detect_labels.return_value = {
            "Labels": [{"Name": "Dog", "Confidence": 99.0}, {"Name": "Pet", "Confidence": 98.0}]
        }
        # When the handler calls dynamodb.Table(), make it return our moto-created table
        mock_dynamo_table.return_value = mock_table

        # 2. ACT: Call the handler function.
        result = image_processing.handler(s3_event, {})

    # 3. ASSERT: Verify the outcome
    assert result['statusCode'] == 200
    assert "Successfully processed" in result['body']

    # We can still use our local `mock_table` object to verify the data
    ddb_items = mock_table.scan()['Items']
    assert len(ddb_items) == 2
    assert ddb_items[0]['ImageKey'] == original_image_key