# 物流跟踪智能体

[![License: MIT](https://img.shields.io/badge/License-MIT-orange.svg)](LICENSE)
[![华为云](https://img.shields.io/badge/华为云-F5A623?style=flat&logo=huawei)](https://www.huaweicloud.com/)
[![Build](https://img.shields.io/badge/构建-通过-green)](https://github.com/huaweicloud-samples/sample-logistics-agent-agentcore-runtime)

## 简介

本项目演示如何在华为云上构建一个具有 VPC 网络连接功能的物流跟踪智能体。该智能体使用 Strands Agents SDK 构建，通过 FunctionGraph 部署，能够查询私有 GaussDB 数据库来跟踪货物运输并识别潜在延误。

### 核心功能

- **智能货物查询**：使用自然语言查询货物运输状态
- **延误风险识别**：自动识别有延误风险的货物
- **物流地点查询**：查询物流节点详细信息
- **完整追踪历史**：获取货物完整运输轨迹

### 核心价值

1. **Serverless 架构**：零服务器运维，按需付费
2. **VPC 私有网络**：数据库完全隔离，确保数据安全
3. **AI 驱动**：基于大语言模型的自然语言交互

### 适用场景

- 物流公司货物跟踪系统
- 供应链管理可视化
- 运输延误预警

## 目录

- [架构图](#架构图)
- [方案亮点](#方案亮点)
- [涉及云服务](#涉及云服务)
- [前置条件](#前置条件)
- [快速开始](#快速开始)
- [分步部署](#分步部署)
- [使用方法](#使用方法)
- [详细说明](#详细说明)
- [依赖与致谢](#依赖与致谢)
- [FAQ](#faq)
- [贡献指南](#贡献指南)
- [清理资源](#清理资源)
- [许可证](#许可证)
- [联系方式](#联系方式)

## 架构图

```
┌─────────────────────────────────────────────────────────────┐
│                        用户请求                               │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                      API Gateway                            │
│                   (APIG 专享实例)                           │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                   FunctionGraph                            │
│              (物流查询智能体函数)                           │
│  ┌─────────────────────────────────────────────────────┐  │
│  │              Strands Agents SDK                      │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌────────────┐  │  │
│  │  │ get_shipment│  │ find_delayed│  │ track_    │  │  │
│  │  │ _status     │  │ _shipments  │  │ shipment  │  │  │
│  │  └─────────────┘  └─────────────┘  └────────────┘  │  │
│  └─────────────────────────────────────────────────────┘  │
│                          │                                  │
│                          ▼                                  │
│  ┌─────────────────────────────────────────────────────┐  │
│  │              华为云 MaaS (DeepSeek-V4)               │  │
│  └─────────────────────────────────────────────────────┘  │
└─────────────────────────┬───────────────────────────────────┘
                          │ VPC 私有网络
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                     GaussDB                                │
│                (私有数据库实例)                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │ shipments    │  │ locations    │  │ shipment_    │    │
│  │              │  │              │  │ events       │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## 方案亮点

- **全托管智能体**：无需运维智能体服务，专注业务逻辑
- **私有数据访问**：数据库部署在 VPC 内，确保数据安全
- **自然语言交互**：用户无需了解数据库结构，通过自然语言查询

## 涉及云服务

本实践涉及以下华为云服务：

| 服务 | 用途 |
|------|------|
| FunctionGraph | 智能体函数计算 |
| APIG | API 网关 |
| GaussDB | 私有数据库 |
| VPC | 虚拟私有云 |
| NAT 网关 | 私有网络公网访问 |
| IAM | 身份认证与授权 |
| MaaS | 大语言模型服务 |

> 部署完成后请记得清理资源，避免资源残留。

## 前置条件

| 工具 | 最低版本 | 用途 |
|------|---------|------|
| Python | 3.11+ | 后端开发 |
| Terraform | 1.5+ | 基础设施部署 |
| 华为云 CLI | 最新版 | 资源管理 |

**华为云要求：**
- 华为云账户（已实名）
- MaaS API Key（从 ModelArts Studio 创建）
- 目标区域：华北三（cn-north-1）

## 快速开始

```bash
# 1. 克隆仓库
git clone https://github.com/huaweicloud-samples/sample-logistics-agent-agentcore-runtime.git
cd sample-logistics-agent-agentcore-runtime

# 2. 配置凭据
export HW_ACCESS_KEY="your-access-key"
export HW_SECRET_KEY="your-secret-key"

# 3. 部署
cd infra
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## 分步部署

### 步骤 1：配置变量

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
```

编辑 `terraform.tfvars`，配置以下变量：

```hcl
project_name    = "logistics-agent"
hw_region       = "cn-north-1"
maas_api_key    = "your-maas-api-key"
```

### 步骤 2：初始化数据库

```bash
# 获取数据库连接信息
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
DB_PASSWORD=$(terraform output -raw db_password)

# 执行 schema
PGPASSWORD=$DB_PASSWORD psql \
  -h $RDS_ENDPOINT \
  -U root \
  -d company_logistics_db \
  -f ../src/schema.sql

# 导入种子数据
PGPASSWORD=$DB_PASSWORD psql \
  -h $RDS_ENDPOINT \
  -U root \
  -d company_logistics_db \
  -f ../src/seed_data.sql
```

### 步骤 3：验证部署

```bash
# 获取 API 端点
API_ENDPOINT=$(terraform output -raw api_endpoint)

# 测试查询
curl -s -X POST "$API_ENDPOINT/query" \
  -H "Content-Type: application/json" \
  -d '{"query": "查询货物运输状态"}'
```

## 使用方法

部署完成后，可通过以下方式调用智能体：

### 查询货物状态

```bash
API_ENDPOINT=$(terraform output -raw api_endpoint)

curl -s -X POST "$API_ENDPOINT/query" \
  -H "Content-Type: application/json" \
  -d '{"query": "CUST-REF-1001 的运输状态是什么？"}'
```

### 查询延误货物

```bash
curl -s -X POST "$API_ENDPOINT/query" \
  -H "Content-Type: application/json" \
  -d '{"query": "哪些货物有延误风险？"}'
```

### 查询物流地点

```bash
curl -s -X POST "$API_ENDPOINT/query" \
  -H "Content-Type: application/json" \
  -d '{"query": "上海物流中心的信息是什么？"}'
```

### 追踪货物历史

```bash
curl -s -X POST "$API_ENDPOINT/query" \
  -H "Content-Type: application/json" \
  -d '{"query": "显示 CUST-REF-1001 的完整运输历史"}'
```

> 部署完成后请按上述步骤自行验证，确认业务功能可用。

## 详细说明

### 工作原理

1. 用户通过 HTTP 请求发送自然语言查询
2. APIG 接收请求并转发到 FunctionGraph 函数
3. FunctionGraph 函数初始化 Strands Agents 智能体
4. 智能体根据查询意图调用对应的数据库工具函数
5. 工具函数查询 GaussDB 数据库获取数据
6. 智能体将查询结果返回给用户

### API 接口

| 接口 | 方法 | 说明 |
|------|------|------|
| `/query` | POST | 智能体查询入口 |

**请求格式：**

```json
{
  "query": "您的自然语言问题"
}
```

**响应格式：**

```json
{
  "result": "智能体回答内容"
}
```

### 配置项说明

| 变量 | 说明 | 默认值 |
|------|------|-------|
| project_name | 项目名称 | logistics-agent |
| hw_region | 部署区域 | cn-north-1 |
| maas_api_key | MaaS API Key | - |

## 依赖与致谢

### 主要依赖

| 依赖 | 版本 | 用途 |
|------|------|------|
| strands-agents | 最新版 | 智能体 SDK |
| pg8000 | 最新版 | PostgreSQL 客户端 |
| huaweicloudsdkcore | >=3.0 | 华为云 SDK 核心 |

### 致谢

本项目基于 Strands Agents SDK 构建，感谢华为云提供的技术支持。

## FAQ

### Q1: 如何获取 MaaS API Key？

1. 登录华为云控制台
2. 进入 ModelArts Studio
3. 创建 API Key
4. 妥善保存密钥

### Q2: 数据库连接失败怎么办？

1. 检查安全组是否放行数据库端口
2. 确认 VPC 配置正确
3. 验证凭据信息

### Q3: 函数调用超时如何处理？

1. 检查 GaussDB 实例状态
2. 增加 FunctionGraph 超时时间
3. 优化 SQL 查询性能

## 贡献指南

欢迎贡献代码！请阅读 [CONTRIBUTING.md](CONTRIBUTING.md) 了解如何参与项目开发。

## 清理资源

```bash
cd infra
terraform destroy
```

## 许可证

本项目采用 MIT No Attribution 许可证开源。详见 [LICENSE](LICENSE) 文件。

## 联系方式

- **维护团队**：公有云持续运营部
- **项目地址**：https://github.com/huaweicloud-samples/sample-logistics-agent-agentcore-runtime
