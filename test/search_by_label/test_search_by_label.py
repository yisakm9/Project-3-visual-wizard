import pytest
import json # <-- 1. Import the json library
from src.search_by_label import search_by_label

# Test that the handler returns a 400 error if the 'label' query parameter is missing.
def test_handler_missing_label():
    # This simulates an API Gateway event with no query string parameters.
    mock_event = {
        "queryStringParameters": None
    }
    
    response = search_by_label.handler(mock_event, None)
    
    # <-- 2. Decode the JSON body from a string into a Python dictionary -->
    body = json.loads(response['body'])
    
    assert response['statusCode'] == 400
    # <-- 3. Assert the value of the 'error' key in the decoded body -->
    assert body['error'] == 'Query parameter "label" is required.'