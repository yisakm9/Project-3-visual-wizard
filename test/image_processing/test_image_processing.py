import pytest
import boto3
from moto import mock_aws
import os
import urllib.parse
import logging

from src.image_processing import image_processing

@mock_aws
def test_successful_image_processing(monkeypatch, caplog):
    """
    Tests the main success path of the image_processing Lambda handler.
    """
    # 1. ARRANGE
    table_name = "mock-visual-wizard-table"
    monkeypatch.setenv("DYNAMODB_TABLE_NAME", table_name)

    class MockRekognitionClient:
        def detect_labels(self, Image, MaxLabels, MinConfidence):
            return {"Labels": [{"Name": "Dog", "Confidence": 99.0}]}

    monkeypatch.setattr(image_processing, "rekognition_client", MockRekognitionClient())
    mocked_dynamodb_resource = boto3.resource("dynamodb", region_name="us-east-1")
    monkeypatch.setattr(image_processing, "dynamodb", mocked_dynamodb_resource)

    s3_client = boto3.client("s3", region_name="us-east-1")
    bucket_name = "test-bucket-123"
    original_image_key = "my dog photo.jpg"
    encoded_image_key = urllib.parse.quote_plus(original_image_key)

    s3_client.create_bucket(Bucket=bucket_name)
    table = mocked_dynamodb_resource.create_table(
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

    # 2. ACT
    # Set the log level to INFO so we can capture our canary message
    with caplog.at_level(logging.INFO):
        result = image_processing.handler(s3_event, {})

    # 3. ASSERT
    
    # --- CANARY ASSERTION ---
    # This test will now fail if the runner is using an old version of the code.
    assert "--- EXECUTING LATEST CODE VERSION V3 ---" in caplog.text
    
    assert result['statusCode'] == 200
    ddb_items = table.scan()['Items']
    assert len(ddb_items) == 1
    assert ddb_items[0]['ImageKey'] == original_image_key