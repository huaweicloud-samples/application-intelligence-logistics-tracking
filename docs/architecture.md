# 架构文档 — 物流跟踪智能体

## 系统架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         API Gateway                                │
│                    (APIG - HTTPS 443)                            │
└────────────────────┬──────────────────────────────────────────────┘
                     │
                     │ HTTP POST /query
                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    FunctionGraph                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  logistics_query (Python Function)                     │   │
│  │  - 使用 Strands Agents SDK                              │   │
│  │  - MaaS 模型调用                                       │   │
│  │  - RDS 数据库查询工具                                   │   │
│  └─────────────────────────────────────────────────────────┘   │
└────────────────────┬──────────────────────────────────────────────┘
                     │
                     │ VPC 内网访问
                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      VPC (10.0.0.0/16)                           │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │
│  │  子网-A (10.0.1.0/24) │  │  子网-B (10.0.2.0/24) │  │  NAT Gateway │     │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘     │
│  ┌─────────────────────────────────────────────────────────┐        │
│  │              RDS PostgreSQL (rds.mysql.s1.small)       │        │
│  │  - 数据库: company_logistics_db                      │        │
│  │  - 表: logistics.shipments, logistics.locations 等   │        │
│  └─────────────────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────────────────────┘
```

## 组件说明

### 1. API Gateway (APIG)

- 提供 HTTPS 端点供外部调用
- 请求认证和流量控制
- 路由到 FunctionGraph 函数

### 2. FunctionGraph

- **主函数**: `logistics_query`
  - 入口点，处理用户查询
  - 使用 Strands Agents SDK 构建智能体
  - 集成两个数据库工具：`get_shipment_status` 和 `find_delayed_shipments`
  - 调用 MaaS 模型进行自然语言理解

### 3. VPC 网络

- **VPC**: 10.0.0.0/16
- **子网-A**: 10.0.1.0/24 (可用区 A)
- **子网-B**: 10.0.2.0/24 (可用区 B)
- **NAT 网关**: 允许函数访问互联网（下载依赖、调用外部 API）

### 4. RDS PostgreSQL

- **规格**: rds.mysql.s1.small (PostgreSQL)
- **数据库名**: company_logistics_db
- **表结构**:
  - `logistics.shipments` - 货物主表
  - `logistics.locations` - 地点表
  - `logistics.tracking_events` - 跟踪事件
  - `logistics.v_shipment_latest_event` - 最新事件视图
  - `logistics.mv_eta_risk` - 延误风险物化视图

## 数据流

1. 用户发送查询到 APIG
2. APIG 转发请求到 FunctionGraph
3. FunctionGraph 初始化 Strands Agent
4. Agent 分析用户意图，决定调用工具
5. 工具执行 SQL 查询 RDS
6. 结果返回给 Agent
7. Agent 调用 MaaS 生成自然语言回答
8. 响应返回给用户

## 安全考虑

- RDS 在私有子网中，不直接暴露到公网
- FunctionGraph 通过 VPC 访问 RDS
- API 调用需要认证
- MaaS API Key 存储在环境变量中

## 部署拓扑

| 资源 | 数量 | 说明 |
|------|------|------|
| VPC | 1 | 私有网络 |
| 子网 | 2 | 可用区 A/B |
| NAT 网关 | 1 | 出站访问 |
| RDS | 1 | PostgreSQL |
| 安全组 | 2 | RDS/FunctionGraph |
| FunctionGraph | 1 | 主函数 |
| APIG | 1 | API 网关 |
