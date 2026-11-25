#!/usr/bin/env bash
set -euo pipefail

# Prepares everything for the Quarkus Insights #330 demos.
# Repos land in qi330-demo/ inside this repo (override with DEMO_DIR=...).
# Safe to re-run: existing clones are kept.
#
# Requirements: git, Java 21+, Maven (wrappers are used), jbang, jq, Podman or Docker.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"   # <repo>/scripts
# Default: qi330-demo/ inside this repo, resolved from the script location (not the current directory).
DEMO_DIR="${DEMO_DIR:-$(dirname "$SCRIPT_DIR")/qi330-demo}"
echo "Demo directory: $DEMO_DIR"

# Start from a clean state: remove every folder under qi330-demo (files such as .gitkeep are kept)
if [ -d "$DEMO_DIR" ]; then
  echo "Cleaning $DEMO_DIR ..."
  find "$DEMO_DIR" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +
fi

MTOOL_VERSION="1.0.6"
QUARKIT_VERSION="2.0.3"

# clone <url> <dir> [ref]
clone() {
  if [ -d "$2" ]; then
    echo "$(basename "$2") already cloned, skipping."
  else
    git clone -q "$1" "$2"
    if [ -n "${3:-}" ]; then git -C "$2" checkout -q "$3"; fi
  fi
}

# Copy the skills under agent skill folder. Default is: .claude/skills
# using the command: install_skill <dir>
# Create the .quarkus-migration.yml file containing different k: v
# needed to automate the AI migration execution
install_skill() {
  mkdir -p "$1/.claude/skills"
  cp -R "$SKILL_DIR" "$1/.claude/skills/"
  printf 'strategy: full-quarkus\nmode: non-interactive\n' > "$1/.quarkus-migration.yml"
}

# copy_app <name under applications/> <target dir> [dest name]
copy_app() {
  local dest="$2/${3:-$1}"
  if [ -d "$dest" ]; then
    echo "${dest#"$DEMO_DIR"/} already exists, skipping."
  else
    mkdir -p "$2"
    rsync -a --exclude target "$APPS_DIR/$1/" "$dest/"
    echo "Copied applications/$1 to ${dest#"$DEMO_DIR"/}"
  fi
}

# setup_demo mtool|quarkit
setup_demo() {
  local dir="$DEMO_DIR/$1"
  copy_app spring-boot-todo-app "$dir"
  copy_app spring-boot-todo-app-quarkus "$dir" spring-boot-todo-app-quarkus-migrated
  case "$1" in
    mtool)
      copy_app cookbook "$dir"
      cp "$SCRIPT_DIR/todo-app-rewrite.patch" "$dir" ;;
    quarkit)
      install_skill "$dir/spring-boot-todo-app"
      cp "$SCRIPT_DIR/break-entity.patch" "$SCRIPT_DIR/mcp-config.json" "$dir"
      cd "$dir/spring-boot-todo-app-quarkus-migrated" && ./mvnw -q package -DskipTests ;;
  esac
}

# --- mtool, acp CLI & MCP server (stdio or http) ---
# Without a version, the jbang alias installs today's early-access build.
# jbang may ask to trust the catalog URL: answer it here, not on stage.
echo "Install mtool CLI - $MTOOL_VERSION"
jbang app install --force "mtool@snowdrop/quarkit/$MTOOL_VERSION"

echo "Install latest ACP client version ..."
jbang app install --force "acp@smallrye/smallrye-acp-client"

# --- Git clone the skill to migrate Spring Boot to Quarkus ---
clone https://github.com/quarkusio/skills.git "$DEMO_DIR/quarkus-skills"

SKILL_DIR="$DEMO_DIR/quarkus-skills/skills/migrate-spring-to-quarkus"
echo "SKILL_DIR=$SKILL_DIR"

# Copy the applications of this repo to the folders used by the different demos:
#   qi330-demo/mtool   : deterministic migration (openrewrite), needs the cookbook rules
#   qi330-demo/quarkit : AI assisted migration (MCP), needs the skill installed in the app
APPS_DIR="$SCRIPT_DIR/../applications"

setup_demo mtool
setup_demo quarkit

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

Note: the Quarkit MCP server listens on 8080, so run the migrated todo app on 8090
(see demo/README.md, block e). Podman or Docker must be running for its Dev Services MySQL.
EOF
