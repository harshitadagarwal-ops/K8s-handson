"""Unit tests for the frontend app."""
import pytest
from unittest.mock import patch, MagicMock
import json

# Import the Flask app
from app import app


@pytest.fixture
def client():
    """Create a test client for the Flask app."""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


class TestHealthEndpoint:
    """Tests for the /health endpoint."""

    def test_health_returns_ok(self, client):
        """Test that health endpoint returns 200 with ok status."""
        response = client.get('/health')
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['status'] == 'ok'


class TestIndexEndpoint:
    """Tests for the / endpoint."""

    @patch('app.requests.get')
    def test_index_success(self, mock_get, client):
        """Test index page loads successfully with messages."""
        mock_response = MagicMock()
        mock_response.json.return_value = {
            'messages': [
                {'id': 1, 'text': 'Hello', 'created_at': '2024-01-01 00:00:00'}
            ]
        }
        mock_response.raise_for_status = MagicMock()
        mock_get.return_value = mock_response

        response = client.get('/')
        assert response.status_code == 200
        assert b'Hello' in response.data

    @patch('app.requests.get')
    def test_index_backend_error(self, mock_get, client):
        """Test index page handles backend errors gracefully."""
        mock_get.side_effect = Exception('Connection refused')

        response = client.get('/')
        assert response.status_code == 200  # Page still loads
        assert b'Could not reach backend' in response.data


class TestAddEndpoint:
    """Tests for the /add endpoint."""

    @patch('app.requests.post')
    def test_add_message_success(self, mock_post, client):
        """Test adding a message redirects to index."""
        mock_post.return_value = MagicMock()

        response = client.post('/add', data={'text': 'New message'})
        assert response.status_code == 302  # Redirect
        assert response.location == '/'

    @patch('app.requests.post')
    def test_add_empty_message(self, mock_post, client):
        """Test adding empty message doesn't call backend."""
        response = client.post('/add', data={'text': ''})
        assert response.status_code == 302  # Still redirects
        mock_post.assert_not_called()

    @patch('app.requests.post')
    def test_add_message_backend_error(self, mock_post, client):
        """Test adding message when backend fails still redirects."""
        mock_post.side_effect = Exception('Connection refused')

        response = client.post('/add', data={'text': 'Test'})
        assert response.status_code == 302  # Still redirects
