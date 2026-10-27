path "secret/data/opentofu/state" { capabilities = ["read"] }
path "secret/data/opentofu/ci" { capabilities = ["read"] }
path "secret/data/opentofu/proxmox" { capabilities = ["read"] }
path "secret/data/opentofu/technitium" { capabilities = ["read"] }
path "secret/data/opentofu/backup-agent" { capabilities = ["read"] }
path "secret/data/packer/proxmox-token" { capabilities = ["read"] }
path "secret/metadata/packer/proxmox-token" { capabilities = ["read"] }
