terraform {
  required_version = ">= 1.11"
  required_providers {
    vault = {
      source  = "opentofu/vault"
      version = "~> 5.13.0"
    }
  }

  backend "s3" {
    bucket = "ma-infra-tfstate"
    key    = "openbao/terraform.tfstate"
    region = "eu-west-par"
    endpoints = {
      s3 = "https://s3.eu-west-par.io.cloud.ovh.net"
    }
    use_lockfile                = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_region_validation      = true
  }
}

provider "vault" {
  address = "https://bao.macopla.com:8200"
}
