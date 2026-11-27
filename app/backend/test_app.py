"""Unit tests for the backend API."""
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


class TestMessagesEndpoint:
    """Tests for the /api/messages endpoints."""

    @patch('app.get_connection')
    def test_list_messages_success(self, mock_conn, client):
        """Test listing messages returns correct data."""
        # Setup mock
        mock_cursor = MagicMock()
        mock_cursor.fetchall.return_value = [
            {'id': 1, 'text': 'Hello', 'created_at': '2024-01-01 00:00:00'},
            {'id': 2, 'text': 'World', 'created_at': '2024-01-01 00:00:01'}
        ]
        mock_conn.return_value.__enter__ = MagicMock(return_value=mock_conn.return_value)
        mock_conn.return_value.__exit__ = MagicMock(return_value=False)
        mock_conn.return_value.cursor.return_value.__enter__ = MagicMock(return_value=mock_cursor)
        mock_conn.return_value.cursor.return_value.__exit__ = MagicMock(return_value=False)

        response = client.get('/api/messages')
        assert response.status_code == 200
        data = json.loads(response.data)
        assert 'messages' in data

    @patch('app.get_connection')
    def test_list_messages_db_error(self, mock_conn, client):
        """Test that DB errors return 500."""
        mock_conn.side_effect = Exception('DB connection failed')

        response = client.get('/api/messages')
        assert response.status_code == 500
        data = json.loads(response.data)
        assert 'error' in data

    @patch('app.get_connection')
    def test_add_message_success(self, mock_conn, client):
        """Test adding a message returns 201."""
        mock_cursor = MagicMock()
        mock_conn.return_value.__enter__ = MagicMock(return_value=mock_conn.return_value)
        mock_conn.return_value.__exit__ = MagicMock(return_value=False)
        mock_conn.return_value.cursor.return_value.__enter__ = MagicMock(return_value=mock_cursor)
        mock_conn.return_value.cursor.return_value.__exit__ = MagicMock(return_value=False)

        response = client.post('/api/messages',
                               data=json.dumps({'text': 'Test message'}),
                               content_type='application/json')
        assert response.status_code == 201
        data = json.loads(response.data)
        assert data['status'] == 'created'
        assert data['text'] == 'Test message'

    def test_add_message_empty_text(self, client):
        """Test that empty text returns 400."""
        response = client.post('/api/messages',
                               data=json.dumps({'text': ''}),
                               content_type='application/json')
        assert response.status_code == 400
        data = json.loads(response.data)
        assert 'error' in data

    def test_add_message_missing_text(self, client):
        """Test that missing text returns 400."""
        response = client.post('/api/messages',
                               data=json.dumps({}),
                               content_type='application/json')
        assert response.status_code == 400

    def test_add_message_whitespace_only(self, client):
        """Test that whitespace-only text returns 400."""
        response = client.post('/api/messages',
                               data=json.dumps({'text': '   '}),
                               content_type='application/json')
        assert response.status_code == 400
