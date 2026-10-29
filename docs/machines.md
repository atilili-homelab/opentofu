# Machines et cluster

## Les machines comme données

Une machine = une entrée dans `proxmox/vms.auto.tfvars` ou `lxcs.auto.tfvars`.
Un modèle commenté se trouve en tête de chacun.

| Module        | Rôle                                                               |
| ------------- | ------------------------------------------------------------------ |
| `proxmox-vm`  | VM clonée d'un template Packer (ou depuis un ISO), cloud-init, GPU |
| `proxmox-lxc` | Conteneur LXC                                                      |
| `dns-records` | Un A par machine, un CNAME par service (RFC 2136, clé TSIG)        |

Les nœuds sont déclarés une fois, dans `var.nodes` (`common.auto.tfvars`).

## Adresses et identifiants

Tout découle du `host_id`, choisi à la main :

- **IP** : `10.86.30.{host_id}`
- **VMID** : `30{host_id sur deux chiffres}`

`host_id = 31` → `10.86.30.31`, VMID `3031` : même numéro dans Proxmox, sur le
réseau et dans le DNS.

Le plan vérifie que le `host_id` est compris entre 20 et 99, et unique parmi toutes
les VM et tous les LXC.

## Attributs

| Attribut          | Effet                                                              |
| ----------------- | ------------------------------------------------------------------ |
| `protection`      | Protection contre la suppression (`true` par défaut)               |
| `backup`          | Sauvegarde quotidienne vers PBS (`false` par défaut)               |
| `ha`              | État HA (`started`, `stopped`…) ; absent = pas de HA               |
| `replicate`       | Réplication ZFS vers l'autre nœud ZFS                              |
| `gpu_passthrough` | Passthrough de l'iGPU ; exclut la VM du rééquilibrage HA           |
| `services`        | Un CNAME par nom (ex. `bao` → la machine)                          |
| `tags`            | Groupes Ansible ; `traefik` + `ha` → anti-affinité `traefik-apart` |

Une VM n'est sauvegardée que si `backup = true` sur la machine, et seuls ses
disques `backup = true` sont inclus.

## Le cluster en code

`cluster.tf` (CRS, mapping GPU) · `storages.tf` · `backup.tf` · `ha.tf` ·
`replication.tf` · `access.tf` (utilisateurs, ACL, tokens : voir
[rotation.md](rotation.md)) · `apt.tf` (dépôt no-subscription).

## À savoir en lisant un plan

- `terraform_data.reboot_expected` dans le plan = le changement demande en général
  un redémarrage (CPU, mémoire, GPU, réseau, stockage des disques).
- Une VM avec GPU ne peut viser qu'un nœud présent dans le mapping `gpu-intel` :
  sinon, le plan s'arrête.
- VLAN déduit de l'IP : pas de tag pour le segment 30.
