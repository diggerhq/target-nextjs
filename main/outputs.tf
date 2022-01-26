output "nextjs_deployment_name" {
  value = "${var.environment}-${random_string.unique_deployment_id.result}"
}
