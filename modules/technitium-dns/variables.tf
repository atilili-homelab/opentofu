variable "api_url" {
  type = string
}

variable "token" {
  type      = string
  sensitive = true
  ephemeral = true
}

variable "zone" {
  type    = string
  default = "macopla.home"
}

variable "records" {
  type = map(string) # hostname => IP
}

variable "vault_addr" {
  type = string
}

variable "vault_secret_path" {
  type    = string
  default = "secret/data/opentofu/technitium"
}
