#!/usr/bin/env bash
set -euo pipefail

# Prepares everything for the Quarkus Insights #330 demos.
# Repos land in ../qi330-demo relative to this repo (override with DEMO_DIR=...).
# Safe to re-run: existing clones are kept.
#
# Requirements: git, Java 21+, Maven (wrappers are used), jbang, jq, curl.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEMO_DIR="${DEMO_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)/qi330-demo}"
MTOOL_1_VERSION="1.0.6"
MTOOL_VERSION="2.0.3"
ACP_VERSION="2.0.4"
PETCLINIC_COMMIT="500158f732419217507c7656904b8e6aa1bcc0d6"
mkdir -p "$DEMO_DIR"

clone() { # clone <url> <dir> [ref]
  if [ -d "$2" ]; then
    echo "$(basename "$2") already cloned, skipping."
  else
    git clone -q "$1" "$2"
    if [ -n "${3:-}" ]; then git -C "$2" checkout -q "$3"; fi
  fi
}

# --- (a) quarkit: rules (cookbook/) and spring-boot-todo-app, at the demoed release ---
QUARKIT_DIR="$DEMO_DIR/quarkit"
clone https://github.com/snowdrop/quarkit.git "$QUARKIT_DIR" "$MTOOL_VERSION"
# Work on a branch so the todo app can be reset after `mtool transform`.
git -C "$QUARKIT_DIR" switch -q -c demo 2>/dev/null || git -C "$QUARKIT_DIR" switch -q demo

# --- (a) mtool and acp CLI ---
# Without a version, the jbang alias installs today's early-access build.
# jbang may ask to trust the catalog URL: answer it here, not on stage.
echo "Install mtool CLI - $MTOOL_1_VERSION"
jbang app install --force "mtool@snowdrop/quarkit/$MTOOL_1_VERSION"

echo "Install Quarkit MCP Server - $MTOOL_VERSION"
jbang app install --force "mcp@snowdrop/quarkit"
jbang app install --force "mcp-http@snowdrop/quarkit"

echo "Install ACP client version - $ACP_VERSION ..."
jbang app install --force "acp@smallrye/smallrye-acp-client"

# --- (d) the skill ---
SKILLS_DIR="$DEMO_DIR/quarkus-skills"
clone https://github.com/quarkusio/skills.git "$SKILLS_DIR"
SKILL_DIR="$SKILLS_DIR/skills/migrate-spring-to-quarkus"

# --- (c)(d) Spring PetClinic, the source project (never modified) ---
PETCLINIC_DIR="$DEMO_DIR/spring-petclinic"
clone https://github.com/spring-projects/spring-petclinic.git "$PETCLINIC_DIR" "$PETCLINIC_COMMIT"

# --- (d) a copy for the live agent run, with the skill installed project-local ---
LIVE_DIR="$DEMO_DIR/spring-petclinic-live"
if [ -d "$LIVE_DIR" ]; then
  echo "spring-petclinic-live already exists, skipping."
else
  cp -R "$PETCLINIC_DIR" "$LIVE_DIR"
  mkdir -p "$LIVE_DIR/.claude/skills"
  cp -R "$SKILL_DIR" "$LIVE_DIR/.claude/skills/"
  printf 'strategy: full-quarkus\nmode: non-interactive\n' > "$LIVE_DIR/.quarkus-migration.yml"
fi

# --- (c)(e) the pre-migrated PetClinic ---
MIGRATED_DIR="$DEMO_DIR/spring-petclinic-quarkus"
clone https://github.com/aureamunoz/spring-petclinic-quarkus.git "$MIGRATED_DIR"
echo "Building spring-petclinic-quarkus..."
(cd "$MIGRATED_DIR" && ./mvnw -q package -DskipTests)

# --- demo helpers next to the projects ---
cp "$SCRIPT_DIR/mcp-config.json" "$SCRIPT_DIR/break-entity.patch" "$DEMO_DIR/"

cat <<EOF

Done. Everything is in: $DEMO_DIR

Start the quarkit MCP server in its own terminal and leave it there
(it stops when its stdin closes, so don't background it):

  cd $DEMO_DIR
  jbang -Dquarkit.allowed-dirs=$DEMO_DIR \\
        --deps dev.snowdrop.mtool:references:$MTOOL_VERSION \\
        dev.snowdrop.mtool:mcp:$MTOOL_VERSION:runner

Then check it from another terminal:

  $DEMO_DIR/mcp-call.sh tools/list | jq -r '.result.tools[].name'

Note: the MCP server listens on 8080, so run the migrated PetClinic on another port
(see demo/README.md, block e).
EOF
