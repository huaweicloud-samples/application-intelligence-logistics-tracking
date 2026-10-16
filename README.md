# Logistics Tracking Agent

[![License: MIT](https://img.shields.io/badge/License-MIT-orange.svg)](LICENSE)
[![Huawei Cloud](https://img.shields.io/badge/华为云-F5A623?style=flat&logo=huawei)](https://www.huaweicloud.com/)
[![Build](https://img.shields.io/badge/Build-Passing-green)](https://github.com/huaweicloud-samples/sample-logistics-agent-agentcore-runtime)

## Overview

This project demonstrates how to build a logistics tracking agent with VPC network connectivity on Huawei Cloud. The agent is built using Strands Agents SDK, deployed via FunctionGraph, and can query a private GaussDB database to track shipments and identify potential delays.

### Core Features

- **Natural Language Query**: Query shipment status using natural language
- **Delay Risk Identification**: Automatically identify shipments at risk of delay
- **Location Lookup**: Query detailed logistics location information
- **Complete Tracking History**: View full shipment tracking history

### Core Value

1. **Serverless Architecture**: Zero server maintenance, pay-as-you-go
2. **VPC Private Network**: Fully isolated database for data security
3. **AI-Powered**: Large language model for natural language interaction

### Use Cases

- Logistics company shipment tracking
- Supply chain management visualization
- Shipping delay warning

## Table of Contents

- [Architecture](#architecture)
- [Key Features](#key-features)
- [Involved Cloud Services](#involved-cloud-services)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Step-by-Step Deployment](#step-by-step-deployment)
- [Usage](#usage)
- [Detailed Documentation](#detailed-documentation)
- [Dependencies & Acknowledgments](#dependencies--acknowledgments)
- [FAQ](#faq)
- [Contributing Guide](#contributing-guide)
- [Cleanup](#cleanup)
- [License](#license)
- [Contact](#contact)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        User Request                          │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                      API Gateway                            │
│                   (APIG Dedicated Instance)                │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                   FunctionGraph                            │
│              (Logistics Query Agent Function)              │
│  ┌─────────────────────────────────────────────────────┐  │
│  │              Strands Agents SDK                      │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌────────────┐  │  │
│  │  │ get_shipment│  │ find_delayed│  │ track_     │  │  │
│  │  │ _status     │  │ _shipments  │  │ shipment   │  │  │
│  │  └─────────────┘  └─────────────┘  └────────────┘  │  │
│  └─────────────────────────────────────────────────────┘  │
│                          │                                  │
│                          ▼                                  │
│  ┌─────────────────────────────────────────────────────┐  │
│  │              Huawei Cloud MaaS (DeepSeek-V4)          │  │
│  └─────────────────────────────────────────────────────┘  │
└─────────────────────────┬───────────────────────────────────┘
                          │ VPC Private Network
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                     GaussDB                                │
│                (Private Database Instance)                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │ shipments    │  │ locations    │  │ shipment_    │    │
│  │              │  │              │  │ events       │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## Key Features

- **Fully Managed Agent**: No agent service maintenance, focus on business logic
- **Private Data Access**: Database deployed in VPC for maximum security
- **Natural Language Interaction**: Users don't need to understand database schema

## Involved Cloud Services

This solution involves the following Huawei Cloud services:

| Service | Usage |
|---------|-------|
| FunctionGraph | Agent function compute |
| APIG | API Gateway |
| GaussDB | Private database |
| VPC | Virtual Private Cloud |
| NAT Gateway | Public network access for private network |
| IAM | Identity and access management |
| MaaS | Large language model service |

> Remember to clean up resources after deployment to avoid residual charges.

## Prerequisites

| Tool | Minimum Version | Purpose |
|------|-----------------|-------|
| Python | 3.11+ | Backend development |
| Terraform | 1.5+ | Infrastructure deployment |
| Huawei Cloud CLI | Latest | Resource management |

**Huawei Cloud Requirements:**
- Huawei Cloud account (verified)
- MaaS API Key (created from ModelArts Studio)
- Target region: cn-north-1

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/huaweicloud-samples/sample-logistics-agent-agentcore-runtime.git
cd sample-logistics-agent-agentcore-runtime

# 2. Configure credentials
export HW_ACCESS_KEY="your-access-key"
export HW_SECRET_KEY="your-secret-key"

# 3. Deploy
cd infra
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Step-by-Step Deployment

### Step 1: Configure Variables

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and configure the following variables:

```hcl
project_name    = "logistics-agent"
hw_region       = "cn-north-1"
maas_api_key    = "your-maas-api-key"
```

### Step 2: Initialize Database

```bash
# Get database connection info
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
DB_PASSWORD=$(terraform output -raw db_password)

# Execute schema
PGPASSWORD=$DB_PASSWORD psql \
  -h $RDS_ENDPOINT \
  -U root \
  -d company_logistics_db \
  -f ../src/schema.sql

# Import seed data
PGPASSWORD=$DB_PASSWORD psql \
  -h $RDS_ENDPOINT \
  -U root \
  -d company_logistics_db \
  -f ../src/seed_data.sql
```

### Step 3: Verify Deployment

```bash
# Get API endpoint
API_ENDPOINT=$(terraform output -raw api_endpoint)

# Test query
curl -s -X POST "$API_ENDPOINT/query" \
  -H "Content-Type: application/json" \
  -d '{"query": "Query shipment status"}'
```

## Usage

After deployment, you can invoke the agent in the following ways:

### Query Shipment Status

```bash
API_ENDPOINT=$(terraform output -raw api_endpoint)

curl -s -X POST "$API_ENDPOINT/query" \
  -H "Content-Type: application/json" \
  -d '{"query": "What is the status of CUST-REF-1001?"}'
```

### Find Delayed Shipments

```bash
curl -s -X POST "$API_ENDPOINT/query" \
  -H "Content-Type: application/json" \
  -d '{"query": "Which shipments are at risk of delay?"}'
```

### Query Location Info

```bash
curl -s -X POST "$API_ENDPOINT/query" \
  -H "Content-Type: application/json" \
  -d '{"query": "What is the information for Shanghai Distribution Center?"}'
```

### Track Shipment History

```bash
curl -s -X POST "$API_ENDPOINT/query" \
  -H "Content-Type: application/json" \
  -d '{"query": "Show complete tracking history for CUST-REF-1001"}'
```

> Please verify the deployment by following the steps above after deployment to confirm business functionality is available.

## Detailed Documentation

### How It Works

1. User sends natural language query via HTTP request
2. APIG receives request and forwards to FunctionGraph function
3. FunctionGraph initializes Strands Agents
4. Agent calls corresponding database tool functions based on query intent
5. Tool functions query GaussDB database
6. Agent returns query result to user

### API Interface

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/query` | POST | Agent query entry point |

**Request Format:**

```json
{
  "query": "Your natural language question"
}
```

**Response Format:**

```json
{
  "result": "Agent response content"
}
```

### Configuration Variables

| Variable | Description | Default |
|----------|-------------|---------|
| project_name | Project name | logistics-agent |
| hw_region | Deployment region | cn-north-1 |
| maas_api_key | MaaS API Key | - |

## Dependencies & Acknowledgments

### Main Dependencies

| Dependency | Version | Usage |
|------------|---------|-------|
| strands-agents | Latest | Agent SDK |
| pg8000 | Latest | PostgreSQL client |
| huaweicloudsdkcore | >=3.0 | Huawei Cloud SDK core |

### Acknowledgments

This project is built using Strands Agents SDK, thanks to Huawei Cloud for technical support.

## FAQ

### Q1: How to get MaaS API Key?

1. Log in to Huawei Cloud Console
2. Go to ModelArts Studio
3. Create API Key
4. Save the key securely

### Q2: What to do if database connection fails?

1. Check if security group allows database port
2. Verify VPC configuration
3. Validate credentials

### Q3: How to handle function timeout?

1. Check GaussDB instance status
2. Increase FunctionGraph timeout
3. Optimize SQL queries

## Contributing Guide

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) to learn how to participate in project development.

## Cleanup

```bash
cd infra
terraform destroy
```

## License

This project is licensed under the MIT No Attribution license. See the [LICENSE](LICENSE) file for details.

## Contact

- **Team**: Public Cloud Continuous Operations
- **Project URL**: https://github.com/huaweicloud-samples/sample-logistics-agent-agentcore-runtime
