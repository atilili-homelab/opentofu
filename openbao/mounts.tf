resource "vault_mount" "secret" {
  path    = "secret"
  type    = "kv"
  options = { version = "2" }

  lifecycle {
    prevent_destroy = true
  }
}

resource "vault_auth_backend" "approle" {
  type = "approle"

  lifecycle {
    prevent_destroy = true
  }
}
