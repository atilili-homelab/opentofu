terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.114.0"
    }
    ovh = {
      source  = "ovh/ovh"
      version = "~> 2.21.0"
    }
    vault = {
      source  = "opentofu/vault"
      version = "~> 5.9.0"
    }
  }

  backend "s3" {
    bucket = "ma-infra-tfstate"
    key    = "prod/terraform.tfstate"
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

provider "proxmox" {
  endpoint  = var.proxmox_url
  api_token = ephemeral.vault_kv_secret_v2.proxmox.data["api_token"]

  ssh {
    agent    = true
    username = "root"
    node {
      name    = "meganode"
      address = "10.86.30.11"
    }
    node {
      name    = "supernode"
      address = "10.86.30.12"
    }
    node {
      name    = "mininode"
      address = "10.86.30.13"
    }
  }
}

provider "ovh" {
  endpoint = "ovh-eu"
}

provider "vault" {
  address            = "http://sati.macopla.home:8200"
  add_address_to_env = true
  skip_child_token   = true

  auth_login {
    path = "auth/approle/login"

    parameters = {
      role_id   = var.login_approle_role_id
      secret_id = var.login_approle_secret_id
    }
  }
}

ephemeral "vault_kv_secret_v2" "proxmox" {
  mount = "secret"
  name  = "opentofu/proxmox"
}

ephemeral "vault_kv_secret_v2" "technitium" {
  mount = "secret"
  name  = "opentofu/technitium"
}
