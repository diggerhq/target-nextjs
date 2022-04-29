
terraform {
  required_version = ">= 0.12"

  # vars are not allowed in this block
  # see: https://github.com/hashicorp/terraform/issues/22088
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }

    archive = {
      source  = "hashicorp/archive"
    }

    local = {
      source  = "hashicorp/local"
    }
  }
}

# Provider used for creating the Lambda@Edge function which must be deployed
# to us-east-1 region (Should not be changed)
provider "aws" {
  region  = var.region
  access_key = var.aws_key
  secret_key = var.aws_secret
}

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

resource "random_string" "unique_deployment_id" {
  length  = 6
  special = false
  lower   = true
  upper   = false
}

module "tf_next" {
  source = "milliHQ/next-js/aws"

  cloudfront_aliases = local.aliases
  cloudfront_acm_certificate_arn = local.acm_certificate_arn
  next_tf_dir               = "${path.module}/../nextjs_app"
  create_image_optimization = false
  deployment_name = "${var.environment}-${random_string.unique_deployment_id.result}"
}


{% if use_dggr_domain %}
  # dggr.app domain
  resource "aws_route53_record" "{{service_name}}_dggr_website_cdn_root_record" {
    provider = aws.digger
    zone_id = "{{dggr_zone_id}}"
    name    = local.{{service_name}}_dggr_website_domain
    type    = "A"

    alias {
      name                   = module.tf_next.cloudfront_domain_name
      zone_id                = module.tf_next.cloudfront_hosted_zone_id
      evaluate_target_health = false
    }
  }
{% endif %}

# digger account provider
provider "aws" {
  alias = "digger"
  region  = var.region
  # profile = var.aws_profile
  access_key = var.digger_aws_key
  secret_key = var.digger_aws_secret
}
