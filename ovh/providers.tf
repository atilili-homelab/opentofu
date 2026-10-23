terraform {
  required_version = ">= 1.11"
  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "~> 2.21.0"
    }
  }

  backend "s3" {
    bucket = "ma-infra-tfstate"
    key    = "ovh/terraform.tfstate"
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

provider "ovh" {
  endpoint = "ovh-eu"
}
