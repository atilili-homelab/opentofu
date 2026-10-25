terraform {
  required_version = ">= 1.11"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.117.0"
    }
    vault = {
      source  = "opentofu/vault"
      version = "~> 5.13.0"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "~> 3.6.2"
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
    dynamic "node" {
      for_each = var.nodes
      content {
        name    = node.key
        address = node.value.address
      }
    }
  }
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

provider "dns" {
  update {
    server        = "10.86.30.42"
    key_name      = "opentofu."
    key_algorithm = "hmac-sha256"
    key_secret    = ephemeral.vault_kv_secret_v2.technitium.data["tsig_secret"]
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
