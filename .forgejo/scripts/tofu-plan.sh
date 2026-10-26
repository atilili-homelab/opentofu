#!/usr/bin/env bash
# Plan de chaque root sans verrou ni apply
set -euo pipefail

# Roots plan et dossier des résultats
ROOTS=(proxmox ovh)
OUT="$PWD/plans"
mkdir -p "$OUT"

# Seule l'AppRole opentofu-ci vient de la forge, le reste est lu dans OpenBao
VAULT_TOKEN="$(printf '%s' "$SECRET_ID" |
    bao write -field=token auth/approle/login role_id="$ROLE_ID" secret_id=-)"
export VAULT_TOKEN
# Le provider vault du root proxmox réutilise ce token pendant le plan : révocation à la sortie seulement
trap 'bao token revoke -self >/dev/null 2>&1 || true' EXIT

# Récupération des secrets sur OpenBao
state="$(bao kv get -mount=secret -format=json opentofu/state | jq '.data.data')"
ovh_ci="$(bao kv get -mount=secret -format=json opentofu/ci | jq '.data.data')"
get() { jq -er --arg k "$2" '.[$k]' <<<"$1"; }

# Construction des variables depuis la sortie jq OpenBao
set -a
# shellcheck disable=SC2034
{
    AWS_ACCESS_KEY_ID="$(get "$state" s3_access_key)"
    AWS_SECRET_ACCESS_KEY="$(get "$state" s3_secret_key)"
    AWS_DEFAULT_REGION=eu-west-par
    TF_VAR_state_passphrase="$(get "$state" state_passphrase)"
    OVH_APPLICATION_KEY="$(get "$ovh_ci" ovh_application_key)"
    OVH_APPLICATION_SECRET="$(get "$ovh_ci" ovh_application_secret)"
    OVH_CONSUMER_KEY="$(get "$ovh_ci" ovh_consumer_key)"
    OVH_ENDPOINT="ovh-eu"
    TF_IN_AUTOMATION=1
    TF_INPUT=0
    TF_PLUGIN_CACHE_DIR="$HOME/.cache/tofu-plugins"
}
set +a

mkdir -p "$TF_PLUGIN_CACHE_DIR"

changes=false
printf '| Root | Résultat |\n| ---- | -------- |\n' >"$OUT/summary.md"

for root in "${ROOTS[@]}"; do
    echo "::group::tofu plan $root"
    tofu -chdir="$root" init
    rc=0
    tofu -chdir="$root" plan -lock=false -detailed-exitcode -out=ci.tfplan || rc=$?
    echo "::endgroup::"

    # -detailed-exitcode : 0 = aucun changement, 2 = diff, le reste = erreur
    if [[ $rc != 0 && $rc != 2 ]]; then
        exit "$rc"
    fi

    tofu -chdir="$root" show -no-color ci.tfplan >"$OUT/$root.txt"
    rm -f "$root/ci.tfplan"

    if [[ $rc == 2 ]]; then
        changes=true
        result="$(grep -m1 '^Plan:' "$OUT/$root.txt" || echo 'Changements')"
    else
        result="Aucun changement"
    fi
    echo "| \`$root\` | $result |" >>"$OUT/summary.md"
done

echo "$changes" >"$OUT/changes"
cat "$OUT/summary.md"
