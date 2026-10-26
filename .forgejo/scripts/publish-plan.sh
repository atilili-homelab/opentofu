#!/usr/bin/env bash
# Ouvre la PR si besoin, y publie le plan, pose le statut tofu/plan et fusionne si rien ne change
set -euo pipefail

API="$FORGEJO_API_URL/repos/$FORGEJO_REPOSITORY"
RUN_URL="$FORGEJO_SERVER_URL/$FORGEJO_REPOSITORY/actions/runs/$FORGEJO_RUN_NUMBER"
BRANCH="$FORGEJO_REF_NAME"
SHA="$FORGEJO_SHA"
MAX_COMMENT=65000

# Fonction qui appelle l'API de Forgejo avec le token d'authentification
api() {
    local method=$1 path=$2
    shift 2
    curl -fsS -X "$method" -H "Authorization: token $FORGE_TOKEN" \
        -H "Content-Type: application/json" "$API$path" "$@"
}

# Récupére le résultat du plan
CHANGES="$(cat plans/changes)"
# Drapeaux posés par le workflow
CREATE_PR="${CREATE_PR:-false}"
ALLOW_MERGE="${ALLOW_MERGE:-false}"

# Choisit STATUS_STATE (pending|success|...), STATUS_DESC et AUTOMERGE (true|false)
# à partir de CHANGES et ALLOW_MERGE.
decide_outcome() {
    if [[ $CHANGES == true ]]; then
        STATUS_STATE=pending
        STATUS_DESC="Changements à relire avant merge"
    else
        STATUS_STATE=success
        STATUS_DESC="Aucun changement"
    fi

    AUTOMERGE=false
    if [[ $CHANGES == false && $ALLOW_MERGE == true ]]; then
        AUTOMERGE=true
    fi
}

#Cherche la PR pour cette branche
pr="$(api GET "/pulls/main/$BRANCH" | jq -r .number)" || pr=""

#Si pas de PR et que CREATE_PR est vrai, on en crée une
if [[ -z $pr && $CREATE_PR == true ]]; then
    title="$(git log -1 --format=%s)"
    pr="$(api POST /pulls -d "$(jq -n --arg h "$BRANCH" --arg t "$title" \
        '{head: $h, base: "main", title: $t}')" | jq -r .number)"
    echo "PR #$pr créée"
fi

decide_outcome

# Pose le statut tofu/plan
api POST "/statuses/$SHA" -d "$(jq -n --arg s "$STATUS_STATE" --arg d "$STATUS_DESC" \
    --arg u "$RUN_URL" '{state: $s, context: "tofu/plan", description: $d, target_url: $u}')" >/dev/null

# Si pas de PR, on s'arrête là
if [[ -z $pr ]]; then
    echo "Pas encore de PR pour $BRANCH, statut posé sur $SHA uniquement"
    exit 0
fi

# Publie le plan dans la PR
{
    echo "### tofu plan — \`${SHA:0:8}\`"
    echo
    cat plans/summary.md
    echo
    for f in plans/*.txt; do
        echo "<details><summary>$(basename "$f" .txt)</summary>"
        echo
        echo '```diff'
        sed -E 's/^( +)([-+~]) /\2\1 /' "$f"
        echo '```'
        echo "</details>"
    done
    echo
    echo "Plans complets dans les artefacts du [run $FORGEJO_RUN_NUMBER]($RUN_URL)."
} >plans/comment.md

# Publie le commentaire dans la PR
body="$(head -c "$MAX_COMMENT" plans/comment.md)"
[[ $(wc -c <plans/comment.md) -gt $MAX_COMMENT ]] && body+=$'\n```\n\n**Tronqué** : voir les artefacts.'
api POST "/issues/$pr/comments" -d "$(jq -n --arg b "$body" '{body: $b}')" >/dev/null

# Si AUTOMERGE est vrai, on fusionne la PR
if [[ $AUTOMERGE == true ]]; then
    # fast-forward-only : ce qui arrive sur main est exactement ce qui a été planifié
    api POST "/pulls/$pr/merge" -d "$(jq -n --arg sha "$SHA" \
        '{Do: "fast-forward-only", head_commit_id: $sha, delete_branch_after_merge: true}')" &&
        echo "PR #$pr fusionnée" ||
        echo "::warning::Fusion de #$pr impossible (main a avancé ?) : rebase la branche"
fi
