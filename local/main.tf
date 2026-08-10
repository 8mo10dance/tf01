terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region                      = "ap-northeast-1"
  access_key                  = "test"
  secret_key                  = "test"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_requesting_account_id  = true

  endpoints {
    s3 = "http://localhost:4566"
  }
}

module "site" {
  source = "../modules/s3-static-site"

  # The ready hook uploads index.html outside Terraform, so allow the disposable local bucket to be destroyed while nonempty.
  bucket_name   = "my-bucket-949926374137-ap-northeast-1-an"
  force_destroy = true
}

output "local_site_url" {
  value = "http://localhost:8080"
}
