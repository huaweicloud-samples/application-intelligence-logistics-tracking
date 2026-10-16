# 部署指南 — 物流跟踪智能体

## 前置条件

| 工具 | 版本 | 用途 |
|------|------|------|
| Terraform | >= 1.5 | 基础设施部署 |
| 华为云 CLI | 最新 | 资源管理（可选） |
| PostgreSQL 客户端 | 15+ | 数据库初始化 |
| Python | 3.11+ | 本地测试（可选） |
| 已有华为云 AK/SK | — | Terraform Provider 认证 |
| MaaS API Key | — | 大模型推理 |

## 部署步骤

### Step 1: 准备 Terraform 环境

```bash
cd infra/

# 配置华为云凭证（环境变量方式）
export HW_ACCESS_KEY="<HW_ACCESS_KEY>"
export HW_SECRET_KEY="<HW_SECRET_KEY>"
export HW_REGION_NAME="cn-north-4"
export HW_PROJECT_NAME="cn-north-4"

# 初始化 Terraform
terraform init
```

### Step 2: 预览变更与费用确认

```bash
terraform plan
```

### Step 3: 部署基础设施

```bash
terraform apply
```

输入 `yes` 确认。部署约需 10-15 分钟（RDS 创建为主要耗时）。

### Step 4: 获取输出信息

```bash
terraform output
```

记录以下输出值：
- `api_endpoint` — APIG 访问地址
- `rds_endpoint` — RDS 连接地址
- `db_name` — 数据库名

### Step 5: 初始化数据库

```bash
# 获取 RDS 连接信息
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
DB_PASSWORD=$(terraform output -raw db_password)

# 执行 schema 和 seed 数据
PGPASSWORD=$DB_PASSWORD psql \
  -h $RDS_ENDPOINT \
  -U root \
  -d company_logistics_db \
  -f src/schema.sql

PGPASSWORD=$DB_PASSWORD psql \
  -h $RDS_ENDPOINT \
  -U root \
  -d company_logistics_db \
  -f src/seed_data.sql

# 验证
PGPASSWORD=$DB_PASSWORD psql \
  -h $RDS_ENDPOINT \
  -U root \
  -d company_logistics_db \
  -c "SELECT COUNT(*) FROM logistics.shipments;"
```

### Step 6: 测试智能体

```bash
API_ENDPOINT=$(terraform output -raw api_endpoint)

# 查询延误货物
curl -s -X POST "$API_ENDPOINT/query" \
  -H "Content-Type: application/json" \
  -d '{"query": "哪些货物有延误风险？"}'

# 查询特定货物
curl -s -X POST "$API_ENDPOINT/query" \
  -H "Content-Type: application/json" \
  -d '{"query": "货物 CUST-REF-1001 的状态是什么？"}'
```

## 清理资源

```bash
cd infra/
terraform destroy
```

输入 `yes` 确认。所有资源将被删除，停止计费。

## 故障排查

### FunctionGraph 连接 RDS 失败

1. 检查 FunctionGraph VPC 配置是否正确绑定
2. 检查安全组是否允许 5432 端口入站
3. 检查 RDS 安全组是否允许 FunctionGraph 安全组来源

### 模型调用失败

1. 检查 NAT Gateway 是否正常运行
2. 检查模型 API Key 是否正确配置为环境变量
3. 检查 MaaS 模型 ID 是否可用
4. 查看 FunctionGraph 日志（LTS）

### APIG 返回 500

1. 查看 FunctionGraph 执行日志
2. 确认函数代码包已正确上传
3. 确认环境变量配置完整
