# DevOps Pipeline Templates

This repository contains reusable CI/CD pipeline templates and sample implementations for various application types.

## Contents

- [Node.js Pipeline Template](#nodejs-pipeline-template)
- [Sample Applications](#sample-applications)
- [Getting Started](#getting-started)

## Node.js Pipeline Template

A comprehensive CI/CD pipeline template for Node.js applications that includes:

### Features

- **Build, Test, and Deploy Stages**: Complete pipeline workflow
- **SonarQube Integration**: Code quality analysis
- **Snyk Security Scanning**: Vulnerability detection
- **Centralized Secrets Management**: Using variable groups
- **Approval Gates**: Manual approval before deployment
- **Slack Notifications**: Build and deployment notifications
- **Parallel Jobs**: Optimized pipeline execution
- **Blue-Green Deployment**: Zero-downtime deployment strategy

### Location

The Node.js pipeline template is located at:

```
.pipelines/nodejs-pipeline-template.yml
```

## Sample Applications

### Node.js Sample Application

A sample Node.js Express application that demonstrates how to use the pipeline template.

#### Features

- REST API endpoints
- Structured logging
- Unit, integration, and smoke tests
- CI/CD pipeline integration

#### Location

```
nodejs-sample/
```

## Getting Started

### Using the Node.js Pipeline Template

1. Reference the template repository in your pipeline:

```yaml
resources:
  repositories:
    - repository: templates
      type: git
      name: DevOps/pipeline-templates
      ref: refs/heads/main
```

2. Extend the template with your parameters:

```yaml
extends:
  template: nodejs-pipeline-template.yml@templates
  parameters:
    projectName: 'your-nodejs-app'
    environment: 'dev'
    nodeVersion: '18.x'
    runSonarQube: true
    runSnyk: true
    requireApproval: false
    sendSlackNotifications: true
    slackChannel: '#your-project-deployments'
```

### Prerequisites

To use these pipeline templates, you need:

1. **Service Connections**:
   - Azure DevOps service connection to your Azure subscription
   - SonarQube service connection
   - Snyk service connection
   - Slack webhook or API token

2. **Variable Groups**:
   - Create a variable group named `{projectName}-{environment}-secrets` for each environment
   - Required secrets: `SLACK_API_TOKEN`, `APPROVERS_EMAIL_LIST`

3. **Azure Resources**:
   - Azure App Service with deployment slots configured for blue-green deployment

## Documentation

For more detailed information, see:

- [Pipeline Templates Documentation](.pipelines/README.md)
- [Node.js Sample Application Documentation](nodejs-sample/README.md)