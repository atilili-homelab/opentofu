resource "vault_policy" "this" {
  for_each = { for f in fileset("${path.module}/policies", "*.hcl") : trimsuffix(f, ".hcl") => f }

  name   = each.key
  policy = file("${path.module}/policies/${each.value}")
}
