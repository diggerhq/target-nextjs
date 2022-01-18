
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

module "tf_next" {
  source = "github.com/diggerhq/terraform-aws-next-js"

  providers = {
    aws.global_region = aws.global_region
  }
  next_tf_dir = "./nextjs_app"
}


# The AWS Profile to use
# variable "aws_profile" {
# }

provider "aws" {
  version = "= 3.37.0"
  region  = var.region
  # profile = var.aws_profile
  access_key = var.aws_key
  secret_key = var.aws_secret  
}
