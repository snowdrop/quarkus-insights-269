SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"   # <repo>/scripts
INSIGHTS_DIR="$(dirname "$SCRIPT_DIR")"        # <repo> = quarkus-insights-330
# Default: qi330-demo/ inside this repo, resolved from the script location (not the current directory).
DEMO_DIR="$INSIGHTS_DIR/qi330-demo"

export QUARKIT_ALLOWED_DIRS=$DEMO_DIR/quarkit
export SKILL_DIR=$DEMO_DIR/quarkus-skills
export ANALYZER_RULES_REPO_URL="https://github.com/snowdrop/quarkit/blob/main/cookbook/rules/quarkus-spring/%s.yaml"

echo "QUARKIT_ALLOWED_DIRS: $QUARKIT_ALLOWED_DIRS"
echo "skill dir: $SKILL_DIR"

echo "Url of the mtool rules: $ANALYZER_RULES_REPO_URL"
echo "Insight dir: $INSIGHTS_DIR"
echo "Demo dir: $DEMO_DIR"