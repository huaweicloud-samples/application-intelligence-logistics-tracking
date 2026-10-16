output "vpc_id" {
  description = "VPC ID"
  value       = huaweicloud_vpc.main.id
}

output "subnet_a_id" {
  description = "Subnet A ID"
  value       = huaweicloud_vpc_subnet.subnet_a.id
}

output "subnet_b_id" {
  description = "Subnet B ID"
  value       = huaweicloud_vpc_subnet.subnet_b.id
}

output "rds_endpoint" {
  description = "GaussDB connection endpoint"
  value       = huaweicloud_gaussdb_instance.main.private_ips[0]
  sensitive  = true
}

output "rds_port" {
  description = "GaussDB port"
  value       = huaweicloud_gaussdb_instance.main.port
}

output "db_name" {
  description = "Database name"
  value       = "company_logistics_db"
}

output "db_user" {
  description = "Database user"
  value       = "root"
}

output "api_endpoint" {
  description = "APIG API endpoint for agent queries"
  value       = "https://${huaweicloud_apig_instance.main.id}.huaweicloudapis.com/query"
}

output "function_urn" {
  description = "FunctionGraph function URN"
  value       = huaweicloud_fgs_function.logistics_query.urn
}
