# Rotation des tokens API

## Packer et Ansible (gérés par OpenTofu)

Dans `proxmox/access.tf`, chaque entrée de `local.managed_tokens` crée :

- `proxmox_user_token.managed["<outil>"]` : le token dans Proxmox ;
- `vault_kv_secret_v2.managed_tokens["<outil>"]` : son secret dans OpenBao
  (`secret/<outil>/proxmox-token`, clé `token`).

Le secret est écrit en **write-only** : OpenTofu ne le relit jamais. Seul le
compteur `version` déclenche une réécriture. Sans lui, `-replace` crée un nouveau
token mais OpenBao garde l'ancien → 401 pour Packer et Ansible.

OpenBao ne contient que la partie après le `=` ; le nom (`packer@pve!packer`) est
déclaré chez le consommateur.

### Procédure (exemple : `packer`)

1. `cd proxmox`, session OpenBao valide (`bao token lookup`).
2. Incrémenter `version` dans `local.managed_tokens`.
3. Planifier :

   ```bash
   tofu plan -replace='proxmox_user_token.managed["packer"]' -out=tfplan
   ```

   Attendu, et rien d'autre :
   - `proxmox_user_token.managed["packer"]` en `-/+` ;
   - `vault_kv_secret_v2.managed_tokens["packer"]` en `~`, seul
     `data_json_wo_version` change.

4. `tofu apply tfplan`. Pas de build Packer ni de playbook pendant l'apply.
   S'il s'interrompt, `tofu plan` + `tofu apply` sans `-replace` termine
   l'écriture.
5. Vérifier :

   ```bash
   curl -s -o /dev/null -w '%{http_code}\n' \
     -H "Authorization: PVEAPIToken=packer@pve!packer=$(bao kv get -mount=secret -field=token packer/proxmox-token)" \
     https://pve.macopla.com/api2/json/version
   ```

   Attendu : `200`.
6. Commiter le bump de `version`.

Pas de retour arrière : l'ancien token est détruit. En cas de problème, refaire une
rotation. Packer, Ansible et la CI relisent OpenBao à chaque exécution : rien à
changer chez eux.

## OpenTofu (créé à la main)

OpenTofu ne gère pas son propre token, pour ne pas pouvoir révoquer la clé qu'il
utilise.

1. Proxmox → Datacenter → Permissions → API Tokens : nouveau token pour
   `opentofu@pve`, **sans** séparation des privilèges.
2. Écrire la chaîne **complète** dans OpenBao, avec `patch` pour garder `ssh_key` :

   ```bash
   bao kv patch -mount=secret opentofu/proxmox api_token='opentofu@pve!<nom>=<secret>'
   ```

3. `tofu plan` dans `proxmox/` : pas d'erreur d'authentification.
4. Supprimer l'ancien token dans Proxmox.

## Les autres

Homarr, Prometheus et PDM : token créé à la main pour l'instant, secret collé dans
l'outil. Leur passage dans `local.managed_tokens` est prévu.
