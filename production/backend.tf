terraform {
  backend "s3" {
    bucket       = "tf01-production-terraform-state-949926374137-ap-northeast-1"
    key          = "production/terraform.tfstate"
    region       = "ap-northeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
