resource "vault_userpass_auth_backend_user" "yoann" {
  mount          = vault_auth_backend.userpass.path
  username       = "yoann"
  token_policies = [vault_policy.this["admin"].name]
  token_ttl      = 86400
  token_max_ttl  = 86400

  password_wo         = var.openbao_yoann_password
  password_wo_version = 1
}
