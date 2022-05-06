
locals {
  {% if acm_certificate_arn_virginia %}
    acm_certificate_arn = "{{acm_certificate_arn_virginia}}"
  {% else %}
    acm_certificate_arn = "{{dggr_acm_certificate_arn_virginia}}"
  {% endif %}

  {% if hostname %}
    aliases = ["{{environment}}-{{service_name}}.{{hostname}}"]
    {{service_name}}_website_domain = "{{environment}}-{{service_name}}.{{hostname}}"

  {% elif dggr_hostname %}
    aliases = ["{{app_name}}-{{environment}}-{{service_name}}.{{dggr_hostname}}"]
    {{service_name}}_dggr_website_domain = "{{app_name}}-{{environment}}-{{service_name}}.{{dggr_hostname}}"
  {% endif %}
}


module "tf_next" {
  source = "github.com/veziak/terraform-aws-next-js"

  providers = {
    aws.global_region = aws.global_region
  }

  cloudfront_aliases = ["{{dggr_subdomain}}.{{dggr_hostname}}"]
  cloudfront_acm_certificate_arn = "{{cloudfront_acm_certificate_arn}}"
  next_tf_dir               = var.nextjs_tf_dir
  create_image_optimization = false
  use_awscli_for_static_upload = true
  deployment_name = "${var.environment}-${random_string.unique_deployment_id.result}"
}


{% if use_dggr_domain %}
  # dggr.app domain
  resource "aws_route53_record" "{{service_name}}_dggr_website_cdn_root_record" {
    provider = aws.digger
    zone_id = "{{dggr_zone_id}}"
    name    = "{{dggr_subdomain}}"
    type    = "A"

    alias {
      name                   = module.tf_next.cloudfront_domain_name
      zone_id                = module.tf_next.cloudfront_hosted_zone_id
      evaluate_target_health = false
    }
  }

output "dggr_route53_record" {
  value = aws_route53_record.{{service_name}}_dggr_website_cdn_root_record.name
}
{% endif %}


output "nextjs_deployment_name" {
  value = "${var.environment}-${random_string.unique_deployment_id.result}"
}

output "static_files_archive" {
  value = module.tf_next.static_files_archive
}

output "static_upload_bucket_id" {
  value = module.tf_next.static_upload_bucket_id
}

