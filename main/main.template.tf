
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

provider "aws" {
  region = var.region
  access_key = var.aws_key
  secret_key = var.aws_secret
}

locals {
  {% if environment_config.hostname %}
    aliases = ["{{environment}}-{{service_name}}.{{environment_config.hostname}}"]
    {{service_name}}_website_domain = "{{environment}}-{{service_name}}.{{environment_config.hostname}}"

  {% elif environment_config.dggr_hostname %}
    aliases = ["{{app_name}}-{{environment}}-{{service_name}}.{{environment_config.dggr_hostname}}"]
    {{service_name}}_dggr_website_domain = "{{app_name}}-{{environment}}-{{service_name}}.{{environment_config.dggr_hostname}}"
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

  cloudfront_aliases = local.aliases
  cloudfront_acm_certificate_arn = local.acm_certificate_arn
  next_tf_dir               = "${path.module}/../nextjs_app"
  create_image_optimization = false
  deployment_name = "${var.environment}-${random_string.unique_deployment_id.result}"
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

  output "{{service_name}}_dggr_domain" {
    value = local.{{service_name}}_dggr_website_domain
  }
{% endif %}

# The AWS Profile to use
# variable "aws_profile" {
# }

provider "aws" {
  region = var.region
  # profile = var.aws_profile
  access_key = var.aws_key
  secret_key = var.aws_secret
}

# digger account provider
provider "aws" {
  alias = "digger"
  region  = var.region
  # profile = var.aws_profile
  access_key = var.digger_aws_key
  secret_key = var.digger_aws_secret
}
