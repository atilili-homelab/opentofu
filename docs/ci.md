# Intégration continue

Forgejo Actions, sur un runner auto-hébergé : la VM `mouse`, avec Nix (label
`nixos`). Les outils sont figés par `flake.lock`. La CI planifie, elle n'applique
jamais : l'apply se fait en local, après la fusion.

## Workflows

| Workflow       | Déclencheur                       | Ce qu'il fait                                        |
| -------------- | --------------------------------- | ---------------------------------------------------- |
| `ci.yml`       | push hors `main` et `renovate/**` | gitleaks, pre-commit, plan ; ouvre et fusionne la PR |
| `renovate.yml` | push sur `renovate/**`            | idem, plan seulement si des fichiers tofu changent   |

Les deux appellent `.forgejo/scripts/tofu-plan.sh` (roots `proxmox/` et `ovh/` ;
`openbao/` reste manuel) et `publish-plan.sh`.

## Après le plan

Le plan est publié en commentaire de la PR, et en artefact `tofu-plan`. Le statut
`tofu/plan` décide de la suite :

- **aucun changement** → `success`, fusion automatique ;
- **changements** → `pending`, je relis le plan et je fusionne à la main.

La fusion est en `fast-forward-only` sur le commit planifié : ce qui arrive sur
`main` est exactement ce qui a été planifié.

## Renovate

Renovate fusionne lui-même les mises à jour mineures et les correctifs des
providers, ainsi que la maintenance des lockfiles. Un `tofu/plan` en `pending`
bloque cette fusion : une mise à jour qui change le plan attend une relecture.

## Identité

- `CI_TOFU_ROLE_ID` / `CI_TOFU_SECRET_ID` : AppRole `opentofu-ci`, échangée contre
  un token OpenBao révoqué en fin de job. Droits : voir [secrets.md](secrets.md).
- `CI_BOT_TOKEN` : compte `ci-bot`, pour la PR, le commentaire et le statut.
