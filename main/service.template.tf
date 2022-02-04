
output "{{service_name}}_lb_dns" {
  value = module.tf_next.cloudfront_domain_name
}

{% if environment_config.dggr_hostname %}
  output "{{service_name}}_dggr_domain" {
    value = "{{app_name}}-{{environment}}-{{service_name}}.{{environment_config.dggr_hostname}}"
  }
{% endif %}