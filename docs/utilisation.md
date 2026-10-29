# Utilisation

## Prérequis

- **Nix** (flakes) et **direnv** : le `flake.nix` fournit opentofu, tflint,
  pre-commit et gitleaks, en versions figées.
- **rbw**, **bao** et **jq**, installés sur le poste : `.envrc` s'en sert pour se
  connecter à OpenBao et lire les secrets.
- Un accès réseau à OpenBao, à l'API Proxmox, au DNS primaire et aux nœuds en SSH
  (dépôt des snippets cloud-init).

Sans rbw ou OpenBao, `.envrc` charge les outils mais pas les secrets.

## Commandes

```bash
direnv allow            # une fois
cd proxmox              # ou une autre root
tofu init
tofu plan -out=tfplan
tofu apply tfplan       # applique exactement le plan relu
```

## Ajouter une machine

Une entrée dans `proxmox/vms.auto.tfvars` ou `lxcs.auto.tfvars`, avec un `host_id`
libre (voir [machines.md](machines.md)).

## Supprimer une machine

La protection Proxmox est active par défaut, donc en deux applies :
`protection = false`, puis retrait de l'entrée.

## Adopter un objet existant

1. Écrire un bloc `import`.
2. `tofu plan -generate-config-out=import.tf` génère un premier jet.
3. Ranger ce code jusqu'à obtenir un plan à **0 changement**.
4. Appliquer, puis retirer le bloc `import`.
