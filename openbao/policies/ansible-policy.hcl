path "secret/data/services/*" { capabilities = ["read"] }
path "secret/metadata/services/*" { capabilities = ["list"] }
path "secret/data/ansible/*" { capabilities = ["read"] }
path "secret/data/ci/*" { capabilities = ["read"] }
path "secret/data/backup/*" { capabilities = ["read"] }
