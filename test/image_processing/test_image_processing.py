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
    table_name = "mock-visual-wizard-table"
    monkeypatch.setenv("DYNAMODB_TABLE_NAME", table_name)

    class MockRekognitionClient:
        def detect_labels(self, Image, MaxLabels, MinConfidence):
            return {"Labels": [{"Name": "Dog", "Confidence": 99.0}, {"Name": "Pet", "Confidence": 98.0}]}

    # Patch the global client objects inside the module we are testing
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

    result = image_processing.handler(s3_event, {})

    assert result['statusCode'] == 200
    assert "Successfully processed" in result['body']

    ddb_items = table.scan()['Items']
    assert len(ddb_items) == 2
    assert ddb_items[0]['ImageKey'] == original_image_key