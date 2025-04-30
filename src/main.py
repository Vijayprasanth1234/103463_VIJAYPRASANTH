#!/usr/bin/env python3
"""
Main module for the application.
"""
import json
import os
import boto3
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def get_secret(secret_name, region_name=None):
    """
    Retrieve a secret from AWS Secrets Manager
    
    Args:
        secret_name (str): The name or ARN of the secret to retrieve
        region_name (str, optional): AWS region name. If None, uses the region from the environment or instance metadata
        
    Returns:
        dict: The secret contents as a dictionary, or None if retrieval failed
    """
    # If region not provided, try to get it from environment or instance metadata
    if not region_name:
        region_name = os.environ.get('AWS_REGION', 'us-east-1')
        
    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(service_name='secretsmanager', region_name=region_name)
    
    try:
        # Get the secret value
        response = client.get_secret_value(SecretId=secret_name)
        
        # Parse and return the secret
        if 'SecretString' in response:
            return json.loads(response['SecretString'])
        else:
            logger.warning(f"Secret {secret_name} does not contain a SecretString")
            return None
    except Exception as e:
        logger.error(f"Error retrieving secret {secret_name}: {str(e)}")
        return None

def load_config():
    """
    Load configuration from files or environment variables
    
    Returns:
        dict: Configuration dictionary
    """
    config = {}
    
    # Try to load from environment variables first
    db_secret_name = os.environ.get('DB_SECRET_NAME')
    app_secret_name = os.environ.get('APP_SECRET_NAME')
    
    # If environment variables not set, use default paths
    if db_secret_name:
        db_config = get_secret(db_secret_name)
        if db_config:
            config['database'] = db_config
            logger.info("Database configuration loaded from Secrets Manager")
    
    if app_secret_name:
        app_config = get_secret(app_secret_name)
        if app_config:
            config.update(app_config)
            logger.info("Application configuration loaded from Secrets Manager")
    
    # If secrets not available, fall back to local config files
    if 'database' not in config:
        try:
            # Try to load from local config file
            config_path = os.environ.get('CONFIG_PATH', '/etc/app/database.json')
            if os.path.exists(config_path):
                with open(config_path, 'r') as f:
                    config['database'] = json.load(f)
                logger.info(f"Database configuration loaded from {config_path}")
            else:
                # Fall back to default settings.json
                with open('config/settings.json', 'r') as f:
                    settings = json.load(f)
                    config['database'] = settings.get('database', {})
                logger.info("Database configuration loaded from settings.json")
        except Exception as e:
            logger.error(f"Error loading configuration: {str(e)}")
            # Set default values
            config['database'] = {
                "host": "localhost",
                "port": 5432,
                "name": "mydb",
                "user": "user"
            }
    
    return config

def main():
    """
    Main function that runs when the script is executed directly.
    """
    print("Hello, World!")
    print("Repository structure has been set up successfully!")
    
    # Load configuration
    config = load_config()
    
    # Log configuration (without sensitive data)
    safe_config = {
        "database": {
            "host": config.get('database', {}).get('host', 'unknown'),
            "port": config.get('database', {}).get('port', 'unknown'),
            "name": config.get('database', {}).get('name', 'unknown'),
            "user": config.get('database', {}).get('user', 'unknown'),
            # Don't log password
        }
    }
    
    print(f"Configuration loaded: {json.dumps(safe_config, indent=2)}")
    
    # Example of using the configuration
    db_config = config.get('database', {})
    print(f"Database connection: {db_config.get('user')}@{db_config.get('host')}:{db_config.get('port')}/{db_config.get('name')}")

if __name__ == "__main__":
    main()