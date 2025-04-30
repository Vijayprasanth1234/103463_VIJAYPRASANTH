"""
Tests for the main module.
"""
import unittest
import sys
import os
import json
from unittest.mock import patch, MagicMock

# Add the parent directory to the path so we can import the src module
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from src.main import main, get_secret, load_config

class TestMain(unittest.TestCase):
    """Test cases for the main module."""
    
    def test_main_runs_without_error(self):
        """Test that the main function runs without raising an exception."""
        # Mock the load_config function to return a test configuration
        test_config = {
            'database': {
                'host': 'test-host',
                'port': 5432,
                'name': 'test-db',
                'user': 'test-user',
                'password': 'test-password'
            }
        }
        
        with patch('src.main.load_config', return_value=test_config):
            try:
                main()
                self.assertTrue(True)  # If we get here, no exception was raised
            except Exception as e:
                self.fail(f"main() raised {type(e).__name__} unexpectedly!")

    @patch('boto3.session.Session')
    def test_get_secret(self, mock_session):
        """Test the get_secret function."""
        # Mock the AWS Secrets Manager client
        mock_client = MagicMock()
        mock_session.return_value.client.return_value = mock_client
        
        # Mock the get_secret_value response
        mock_client.get_secret_value.return_value = {
            'SecretString': json.dumps({
                'username': 'test-user',
                'password': 'test-password'
            })
        }
        
        # Call the function
        result = get_secret('test-secret', 'us-east-1')
        
        # Verify the result
        self.assertEqual(result, {
            'username': 'test-user',
            'password': 'test-password'
        })
        
        # Verify the client was called with the correct parameters
        mock_session.return_value.client.assert_called_with(
            service_name='secretsmanager',
            region_name='us-east-1'
        )
        mock_client.get_secret_value.assert_called_with(SecretId='test-secret')

    @patch('src.main.get_secret')
    @patch('os.environ.get')
    @patch('os.path.exists')
    @patch('builtins.open')
    def test_load_config_with_secrets(self, mock_open, mock_exists, mock_environ_get, mock_get_secret):
        """Test loading configuration from Secrets Manager."""
        # Mock environment variables
        mock_environ_get.side_effect = lambda key, default=None: {
            'DB_SECRET_NAME': 'db-secret',
            'APP_SECRET_NAME': 'app-secret',
            'CONFIG_PATH': '/etc/app/database.json'
        }.get(key, default)
        
        # Mock get_secret responses
        mock_get_secret.side_effect = lambda secret_name, region_name=None: {
            'db-secret': {
                'host': 'secret-host',
                'port': 5432,
                'name': 'secret-db',
                'user': 'secret-user',
                'password': 'secret-password'
            },
            'app-secret': {
                'alarm_email': 'test@example.com',
                'api_keys': {'service1': 'key1', 'service2': 'key2'}
            }
        }.get(secret_name)
        
        # Call the function
        config = load_config()
        
        # Verify the result
        self.assertEqual(config['database']['host'], 'secret-host')
        self.assertEqual(config['database']['user'], 'secret-user')
        self.assertEqual(config['database']['password'], 'secret-password')
        self.assertEqual(config['alarm_email'], 'test@example.com')
        self.assertEqual(config['api_keys'], {'service1': 'key1', 'service2': 'key2'})
        
        # Verify that we didn't try to read from files
        mock_open.assert_not_called()

    @patch('src.main.get_secret')
    @patch('os.environ.get')
    @patch('os.path.exists')
    def test_load_config_fallback_to_file(self, mock_exists, mock_environ_get, mock_get_secret):
        """Test falling back to configuration files when secrets are not available."""
        # Mock environment variables (no secret names)
        mock_environ_get.side_effect = lambda key, default=None: {
            'CONFIG_PATH': '/etc/app/database.json'
        }.get(key, default)
        
        # Mock get_secret to return None (secrets not available)
        mock_get_secret.return_value = None
        
        # Mock file existence
        mock_exists.return_value = True
        
        # Mock file reading
        mock_file = unittest.mock.mock_open(read_data=json.dumps({
            'host': 'file-host',
            'port': 5432,
            'name': 'file-db',
            'user': 'file-user',
            'password': 'file-password'
        }))
        
        with patch('builtins.open', mock_file):
            # Call the function
            config = load_config()
            
            # Verify the result
            self.assertEqual(config['database']['host'], 'file-host')
            self.assertEqual(config['database']['user'], 'file-user')
            self.assertEqual(config['database']['password'], 'file-password')

if __name__ == '__main__':
    unittest.main()