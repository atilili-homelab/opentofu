terraform {
  required_version = ">= 1.11"
  required_providers {
    lldap = {
      source  = "tasansga/lldap"
      version = "~> 0.4.5"
    }
    vault = {
      source  = "opentofu/vault"
      version = "~> 5.13.0"
    }
  }

  backend "s3" {
    bucket = "ma-infra-tfstate"
    key    = "lldap/terraform.tfstate"
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

ephemeral "vault_kv_secret_v2" "lldap" {
  mount = "secret"
  name  = "services/lldap"
}

provider "lldap" {
  http_url = "https://ldap.macopla.com"
  ldap_url = "ldap://authelia_lldap:3890"
  username = "admin"
  password = ephemeral.vault_kv_secret_v2.lldap.data["admin_password"]
  base_dn  = "dc=macopla,dc=com"
}
