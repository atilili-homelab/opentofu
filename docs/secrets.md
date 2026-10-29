# Secrets et state

OpenBao est la source unique. La passphrase du state et les clés S3 ont une copie
de secours dans Bitwarden : sans elles, perdre OpenBao rendrait les states
illisibles.

## Ce qui reste hors du state

- **`ephemeral`** (`proxmox/providers.tf`) : token API Proxmox, clé SSH, clé TSIG.
  Relus à chaque exécution, jamais écrits dans le state ni le plan.
- **Write-only** (`data_json_wo`, `password_wo`) : tokens Packer et Ansible, mot de
  passe OpenBao `yoann`. Voir [rotation.md](rotation.md).

## Ce qui y est, chiffré

- La valeur des `proxmox_user_token`, renvoyée par le provider.
- Le mot de passe PBS, lu par une source `data` (`storages.tf`), en attendant la
  PR bpg #2960.

## Chemins OpenBao (`secret/`)

| Chemin                                                             | Lu par              |
| ------------------------------------------------------------------ | ------------------- |
| `opentofu/state` (S3, passphrase)                                  | local et CI         |
| `opentofu/ovh` (API OVH, écriture)                                 | local               |
| `opentofu/ci` (API OVH, lecture seule)                             | CI                  |
| `opentofu/proxmox`, `opentofu/technitium`, `opentofu/backup-agent` | local et CI         |
| `packer/proxmox-token`, `ansible/proxmox-token` (écrits ici)       | Packer, Ansible, CI |

En local, `.envrc` se connecte avec mon compte (mot de passe dans rbw). En CI,
l'AppRole `opentofu-ci` a sa propre politique, qui ne peut pas lire `opentofu/ovh`.

**Nouveau secret lu par la CI** : l'ajouter à
`openbao/policies/opentofu-ci-policy.hcl` (`secret/data/…`, et `secret/metadata/…`
s'il est écrit par le root `proxmox`), puis appliquer `openbao/` avant de pousser.

## State

- Bucket S3 chez OVH, une clé par root, verrou natif (`use_lockfile`).
- Chiffré côté client (`pbkdf2` + `aes_gcm`, `enforced`), plans compris.
- La CI planifie avec `-lock=false` : elle n'applique jamais.
