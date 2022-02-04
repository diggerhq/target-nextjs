
output "{{service_name}}_lb_dns" {
  value = module.tf_next.cloudfront_domain_name
}

locals {
  {% if environment_config.hostname %}
    aliases = ["{{environment}}-{{service_name}}.{{environment_config.hostname}}"]
    {{service_name}}_website_domain = "{{environment}}-{{service_name}}.{{environment_config.hostname}}"

  {% elif environment_config.dggr_hostname %}
    aliases = ["{{app_name}}-{{environment}}-{{service_name}}.{{environment_config.dggr_hostname}}"]
    {{service_name}}_dggr_website_domain = "{{app_name}}-{{environment}}-{{service_name}}.{{environment_config.dggr_hostname}}"
  {% endif %}
}

{% if environment_config.use_dggr_domain %}
  # dggr.app domain
  resource "aws_route53_record" "{{service_name}}_dggr_website_cdn_root_record" {
    provider = aws.digger
    zone_id = "{{environment_config.dggr_zone_id}}"
    name    = local.{{service_name}}_dggr_website_domain
    type    = "A"

    alias {
      name                   = module.tf_next.cloudfront_domain_name
      zone_id                = module.tf_next.cloudfront_hosted_zone_id
      evaluate_target_health = false
    }
  }
{% endif %}

{% if environment_config.dggr_hostname %}
  output "{{service_name}}_dggr_domain" {
    value = "{{app_name}}-{{environment}}-{{service_name}}.{{environment_config.dggr_hostname}}"
  }
{% endif %}