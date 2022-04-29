output "nextjs_deployment_name" {
  value = "${var.environment}-${random_string.unique_deployment_id.result}"
}


output "{{service_name}}_lb_dns" {
  value = module.tf_next.cloudfront_domain_name
}

{% if dggr_hostname %}
  output "{{service_name}}_dggr_domain" {
    value = "{{app_name}}-{{environment}}-{{service_name}}.{{dggr_hostname}}"
  }
{% endif %}