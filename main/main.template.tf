
terraform {
  required_version = ">= 0.12"

  # vars are not allowed in this block
  # see: https://github.com/hashicorp/terraform/issues/22088
  backend "s3" {}

  required_providers {
    archive = {
      version = "= 1.3.0"
      source  = "hashicorp/archive"
    }

    local = {
      version = "= 1.4.0"
      source  = "hashicorp/local"
    }
  }
}

# Provider used for creating the Lambda@Edge function which must be deployed
# to us-east-1 region (Should not be changed)
provider "aws" {
  alias  = "global_region"
  region = "us-east-1"
}

locals {
  {% if environment_config.hostname %}
    aliases = ["{{environment}}-{{service_name}}.{{environment_config.hostname}}"]
  {% elif environment_config.dggr_hostname %}
    aliases = ["{{app_name}}-{{environment}}-{{service_name}}.{{environment_config.dggr_hostname}}"]
  {% endif %}

  {% if environment_config.acm_certificate_arn_virginia %}
    acm_certificate_arn = "{{environment_config.acm_certificate_arn_virginia}}"
  {% else %}
    acm_certificate_arn = "{{environment_config.dggr_acm_certificate_arn_virginia}}"
  {% endif %}
}

resource "random_string" "unique_deployment_id" {
  length  = 6
  special = false
  lower   = true
  upper   = false
}

module "tf_next" {
  source = "github.com/diggerhq/terraform-aws-next-js"

  providers = {
    aws.global_region = aws.global_region
  }

  cloudfront_aliases = local.aliases
  cloudfront_acm_certificate_arn = local.acm_certificate_arn
  next_tf_dir               = "${path.module}/../nextjs_app"
  create_image_optimization = false
  deployment_name = "${var.environment}-${random_string.unique_deployment_id.result}"
}

/*
{% if environment_config.dns_zone_id %}
  # Creates the DNS record to point on the main CloudFront distribution ID
  resource "aws_route53_record" "{{service_name}}_website_cdn_root_record" {
    zone_id = "{{environment_config.dns_zone_id}}"
    name    = local.{{service_name}}_website_domain
    type    = "A"

    alias {
      name                   = aws_cloudfront_distribution.{{service_name}}_website_cdn_root.domain_name
      zone_id                = aws_cloudfront_distribution.{{service_name}}_website_cdn_root.hosted_zone_id
      evaluate_target_health = false
    }
  }

  output "{{service_name}}_custom_domain" {
    value = local.{{service_name}}_website_domain
  }
{% endif %}
*/

# The AWS Profile to use
# variable "aws_profile" {
# }

provider "aws" {
  region = var.region
  # profile = var.aws_profile
  access_key = var.aws_key
  secret_key = var.aws_secret
}
