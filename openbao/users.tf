resource "vault_userpass_auth_backend_user" "yoann" {
  mount          = vault_auth_backend.userpass.path
  username       = "yoann"
  token_policies = [vault_policy.this["admin"].name]
  token_ttl      = 3600
  token_max_ttl  = 28800

  password_wo         = var.openbao_yoann_password
  password_wo_version = 1
}
