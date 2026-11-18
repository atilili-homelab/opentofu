ephemeral "vault_kv_secret_v2" "openbao_oidc" {
  mount = "secret"
  name  = "services/openbao"
}

resource "vault_jwt_auth_backend" "oidc" {
  path                          = "oidc"
  type                          = "oidc"
  oidc_discovery_url            = "https://sso.macopla.com"
  oidc_client_id                = "openbao"
  oidc_client_secret_wo         = ephemeral.vault_kv_secret_v2.openbao_oidc.data["oidc_client_secret"]
  oidc_client_secret_wo_version = 1
  default_role                  = "admin"
}

resource "vault_jwt_auth_backend_role" "admin" {
  backend               = vault_jwt_auth_backend.oidc.path
  role_name             = "admin"
  role_type             = "oidc"
  user_claim            = "preferred_username"
  groups_claim          = "groups"
  oidc_scopes           = ["openid", "profile", "email", "groups"]
  bound_claims          = { groups = "admins" }
  allowed_redirect_uris = ["https://bao.macopla.com:8200/ui/vault/auth/oidc/oidc/callback"]
  token_policies        = [vault_policy.this["admin"].name]
  token_ttl             = 3600
  token_max_ttl         = 28800
}
