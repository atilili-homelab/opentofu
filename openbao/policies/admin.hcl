# Santé du serveur
path "sys/health" {
  capabilities = ["read", "sudo"]
}

# Politiques
path "sys/policies/acl" { capabilities = ["list"] }
path "sys/policies/acl/*" { capabilities = ["create", "read", "update", "delete", "list", "sudo"] }

# Méthodes d'authentification : les activer, et gérer leur contenu (rôles, utilisateurs)
path "sys/auth" { capabilities = ["read"] }
path "sys/auth/*" { capabilities = ["create", "read", "update", "delete", "list", "sudo"] }
path "auth/*" { capabilities = ["create", "read", "update", "delete", "list", "sudo"] }

# Moteurs de secrets : les monter et les régler
path "sys/mounts" { capabilities = ["read"] }
path "sys/mounts/*" { capabilities = ["create", "read", "update", "delete", "list", "sudo"] }

# Contenu des moteurs
path "secret/*" { capabilities = ["create", "read", "update", "patch", "delete", "list"] }
path "identity/*" { capabilities = ["create", "read", "update", "delete", "list"] }
