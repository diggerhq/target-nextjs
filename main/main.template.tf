
terraform {
  required_version = ">= 0.12"

  # vars are not allowed in this block
  # see: https://github.com/hashicorp/terraform/issues/22088
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }

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
  region  = var.region
  {% if assume_role_arn %}
  assume_role {
    role_arn="{{assume_role_arn}}"
    external_id="{{assume_role_external_id}}"
  }
  {% else %}
  access_key = var.aws_key
  secret_key = var.aws_secret
  {% endif %}
}

locals {
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

# digger account provider
provider "aws" {
  alias = "digger"
  region  = var.region
  # profile = var.aws_profile
  access_key = var.digger_aws_key
  secret_key = var.digger_aws_secret
}
