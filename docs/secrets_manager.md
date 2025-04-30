# AWS Secrets Manager Integration

This document explains how to use AWS Secrets Manager for storing and retrieving sensitive data in this project.

## Overview

AWS Secrets Manager is a service that helps you protect access to your applications, services, and IT resources without the upfront cost and complexity of deploying and maintaining your own infrastructure. The service enables you to easily rotate, manage, and retrieve database credentials, API keys, and other secrets throughout their lifecycle.

## Implementation Details

### Infrastructure (Terraform)

The project uses a dedicated Terraform module (`modules/secrets_manager`) to manage AWS Secrets Manager resources:

1. **KMS Key**: A dedicated KMS key for encrypting secrets
2. **Database Secret**: Stores database credentials
3. **Application Secret**: Stores application-specific secrets like API keys and alarm email addresses
4. **IAM Policy**: Defines permissions for accessing secrets
5. **Secret Rotation**: Optional configuration for automatic secret rotation

### Application Code (Python)

The application code uses the AWS SDK for Python (boto3) to retrieve secrets at runtime:

1. **Secret Retrieval**: The `get_secret` function in `src/main.py` retrieves secrets from AWS Secrets Manager
2. **Configuration Loading**: The `load_config` function loads configuration from Secrets Manager or falls back to local files
3. **Environment Variables**: The application uses environment variables to determine which secrets to retrieve

## How to Use

### Setting Up Secrets

1. Deploy the infrastructure using Terraform:

```bash
terraform init
terraform apply
```

2. Note the secret names from the Terraform outputs:

```
database_secret_name = "dev/example-project/database"
application_secret_name = "dev/example-project/application"
```

### Accessing Secrets in EC2 Instances

EC2 instances in the Auto Scaling Group are configured to:

1. Install the required dependencies (boto3)
2. Fetch secrets during instance startup
3. Store the secrets in local configuration files for application use

### Accessing Secrets in Application Code

```python
import os
import boto3
import json

def get_secret(secret_name, region_name="us-east-1"):
    """Retrieve a secret from AWS Secrets Manager"""
    session = boto3.session.Session()
    client = session.client(service_name='secretsmanager', region_name=region_name)
    
    try:
        response = client.get_secret_value(SecretId=secret_name)
        if 'SecretString' in response:
            return json.loads(response['SecretString'])
        else:
            return None
    except Exception as e:
        print(f"Error retrieving secret: {str(e)}")
        return None

# Get database credentials
db_secret_name = os.environ.get('DB_SECRET_NAME', 'dev/example-project/database')
db_creds = get_secret(db_secret_name)

if db_creds:
    # Use the credentials
    host = db_creds['host']
    username = db_creds['username']
    password = db_creds['password']
```

## IAM Permissions

To access secrets, your EC2 instances or other AWS resources need the following IAM permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:secretsmanager:region:account-id:secret:secret-name-*"
      ]
    },
    {
      "Action": [
        "kms:Decrypt"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:kms:region:account-id:key/key-id"
      ]
    }
  ]
}
```

## Secret Rotation

For production environments, secret rotation is enabled by default. This requires:

1. A Lambda function that can rotate the secrets
2. Appropriate permissions for the Lambda function

To customize rotation settings, modify the following variables:

```hcl
module "secrets_manager" {
  # ...
  enable_rotation     = true
  rotation_lambda_arn = "arn:aws:lambda:region:account-id:function:rotation-function"
  rotation_days       = 30
}
```

## Best Practices

1. **Never hardcode secrets** in your application code or configuration files
2. **Use IAM roles** to grant permissions to EC2 instances or other AWS resources
3. **Enable secret rotation** for production environments
4. **Use KMS customer managed keys** for additional control over encryption
5. **Implement least privilege** when defining IAM policies for accessing secrets
6. **Monitor access** to secrets using CloudTrail and CloudWatch
7. **Implement fallback mechanisms** in case secrets cannot be retrieved