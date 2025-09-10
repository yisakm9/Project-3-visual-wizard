import pytest
from src.search_by_label import search_by_label

# Test that the handler returns a 400 error if the 'label' query parameter is missing.
def test_handler_missing_label():
    # This simulates an API Gateway event with no query string parameters.
    mock_event = {
        "queryStringParameters": None
    }
    
    response = search_by_label.handler(mock_event, None)
    
    assert response['statusCode'] == 400
    assert 'Query parameter "label" is required' in response['body']