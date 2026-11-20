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

# --- (a) mtool: rules (cookbook/) and applications | mtool 1.x ---
MTOOL_1_DIR="$DEMO_DIR/mtool-1.x"
echo "clone https://github.com/snowdrop/quarkit.git $MTOOL_1_DIR $MTOOL_1_VERSION"
clone https://github.com/snowdrop/quarkit.git "$MTOOL_1_DIR" "$MTOOL_1_VERSION"
# Work on a branch so the todo app can be reset after `mtool transform`.
git -C "$MTOOL_1_DIR" switch -q -c demo 2>/dev/null || git -C "$MTOOL_1_DIR" switch -q demo

# --- (a) quarkit: rules (cookbook/) and applications | mtool 2.x ---
QUARKIT_DIR="$DEMO_DIR/quarkit"
echo "clone https://github.com/snowdrop/quarkit.git $QUARKIT_DIR $MTOOL_VERSION"
clone https://github.com/snowdrop/quarkit.git "$QUARKIT_DIR" "$MTOOL_VERSION"
# Work on a branch so the todo app can be reset after `mtool transform`.
git -C "$QUARKIT_DIR" switch -q -c demo 2>/dev/null || git -C "$QUARKIT_DIR" switch -q demo

# --- (a) mtool, acp CLI & MCP server (stdio or http) ---
# Without a version, the jbang alias installs today's early-access build.
# jbang may ask to trust the catalog URL: answer it here, not on stage.
echo "Install mtool CLI - $MTOOL_1_VERSION"
jbang app install --force "mtool@snowdrop/quarkit/$MTOOL_1_VERSION"

echo "Install latest ACP client version ..."
jbang app install --force "acp@smallrye/smallrye-acp-client"

# --- (d) the skill ---
SKILLS_DIR="$DEMO_DIR/quarkus-skills"
clone https://github.com/quarkusio/skills.git "$SKILLS_DIR"
SKILL_DIR="$SKILLS_DIR/skills/migrate-spring-to-quarkus"

# --- (c)(d) Spring PetClinic, the source project (never modified) ---
PETCLINIC_DIR="$DEMO_DIR/spring-petclinic"
clone https://github.com/spring-projects/spring-petclinic.git "$PETCLINIC_DIR" "$PETCLINIC_COMMIT"

# --- (d) copies for the live agent run, with the skill installed project-local ---
install_skill() { # install_skill <dir>: project-local skill + non-interactive config
  mkdir -p "$1/.claude/skills"
  cp -R "$SKILL_DIR" "$1/.claude/skills/"
  printf 'strategy: full-quarkus\nmode: non-interactive\n' > "$1/.quarkus-migration.yml"
}

# Spring PetClinic (the main demo)
LIVE_DIR="$DEMO_DIR/spring-petclinic-live"
if [ -d "$LIVE_DIR" ]; then
  echo "spring-petclinic-live already exists, skipping."
else
  cp -R "$PETCLINIC_DIR" "$LIVE_DIR"
  install_skill "$LIVE_DIR"
fi

# spring-boot-todo-app (a smaller app, faster to migrate live), taken pristine from the
# quarkit release tag (block a may have transformed the working copy).
TODO_LIVE_DIR="$DEMO_DIR/spring-boot-todo-app-live"
if [ -d "$TODO_LIVE_DIR" ]; then
  echo "spring-boot-todo-app-live already exists, skipping."
else
  mkdir -p "$TODO_LIVE_DIR"
  git -C "$QUARKIT_DIR" archive "$MTOOL_VERSION" applications/spring-boot-todo-app \
    | tar -x --strip-components=2 -C "$TODO_LIVE_DIR"
  install_skill "$TODO_LIVE_DIR"
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

Install and start the quarkit MCP server in its own terminal and leave it there
(it stops when its stdin closes, so don't background it):

  cd $DEMO_DIR
  acp mcp add -f -t http quarkit-http http://localhost:8080/mcp -- \\
    jbang --deps dev.snowdrop.mtool:references:2.0.3 mcp-http@snowdrop/quarkit

  acp mcp serve -e QUARKIT_ALLOWED_DIRS=$DEMO_DIR quarkit-http

Then check the available MCP Tools from another terminal:
  acp mcp tools quarkit-http

Note: the Quarkit MCP server listens on 8080, so run the migrated PetClinic on another port
(see demo/README.md, block e).
EOF
