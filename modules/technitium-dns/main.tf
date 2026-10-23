resource "terraform_data" "record" {
  for_each = var.records

  triggers_replace = [each.value]

  input = {
    api_url           = var.api_url
    zone              = var.zone
    domain            = "${each.key}.${var.zone}"
    ip                = each.value
    vault_addr        = var.vault_addr
    vault_secret_path = var.vault_secret_path
  }

  provisioner "local-exec" {
    command = "curl -s '${var.api_url}/api/zones/records/add?token=${var.token}&zone=${var.zone}&domain=${each.key}.${var.zone}&type=A&ipAddress=${each.value}&overwrite=true&createPtrZone=true'"
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      VAULT_TOKEN=$(curl -sf --request POST \
        --data "{\"role_id\":\"$TF_VAR_login_approle_role_id\",\"secret_id\":\"$TF_VAR_login_approle_secret_id\"}" \
        "${self.input.vault_addr}/v1/auth/approle/login" | jq -r '.auth.client_token')
      DNS_TOKEN=$(curl -sf --header "X-Vault-Token: $VAULT_TOKEN" \
        "${self.input.vault_addr}/v1/${self.input.vault_secret_path}" | jq -r '.data.data.token')
      curl -sf "${self.input.api_url}/api/zones/records/delete?token=$${DNS_TOKEN}&zone=${self.input.zone}&domain=${self.input.domain}&type=A&ipAddress=${self.input.ip}"
    EOT
  }
}
