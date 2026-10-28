terraform {
  required_version = ">= 1.11"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.118.0"
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
    key    = "proxmox/terraform.tfstate"
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
    private_key = ephemeral.vault_kv_secret_v2.proxmox.data["ssh_key"]
    username    = "root"
    dynamic "node" {
      for_each = var.nodes
      content {
        name    = node.key
        address = node.value.address
      }
    }
  }
}

# Pas d'auth_login : le token vient de la session (~/.vault-token en local, VAULT_TOKEN en CI)
provider "vault" {
  address            = "https://bao.macopla.com:8200"
  add_address_to_env = true
  skip_child_token   = true
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
