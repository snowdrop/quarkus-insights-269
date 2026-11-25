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
exit
MTOOL_1_VERSION="1.0.6"
MTOOL_VERSION="2.0.3"

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

# --- (b)(c)(d) the Spring source and the live agent run, with the skill installed project-local ---
install_skill() { # install_skill <dir>: project-local skill + non-interactive config
  mkdir -p "$1/.claude/skills"
  cp -R "$SKILL_DIR" "$1/.claude/skills/"
  printf 'strategy: full-quarkus\nmode: non-interactive\n' > "$1/.quarkus-migration.yml"
}

# spring-boot-todo-app, taken pristine from the quarkit release tag (block a may have
# transformed the working copy). The agent only reads it, so it is also the "source" of the
# validator in block c. The agent writes its result to spring-boot-todo-app-live-quarkus/.
TODO_LIVE_DIR="$DEMO_DIR/spring-boot-todo-app-live"
if [ -d "$TODO_LIVE_DIR" ]; then
  echo "spring-boot-todo-app-live already exists, skipping."
else
  mkdir -p "$TODO_LIVE_DIR"
  git -C "$QUARKIT_DIR" archive "$MTOOL_VERSION" applications/spring-boot-todo-app \
    | tar -x --strip-components=2 -C "$TODO_LIVE_DIR"
  install_skill "$TODO_LIVE_DIR"
fi

# --- (c)(e) the pre-migrated todo app, from this repo's fallback (unedited agent output + dev seed data) ---
MIGRATED_DIR="$DEMO_DIR/spring-boot-todo-app-quarkus"
if [ -d "$MIGRATED_DIR" ]; then
  echo "spring-boot-todo-app-quarkus already exists, skipping."
else
  rsync -a --exclude target "$SCRIPT_DIR/../applications/spring-boot-todo-app-quarkus/" "$MIGRATED_DIR/"
  echo "Building spring-boot-todo-app-quarkus..."
  (cd "$MIGRATED_DIR" && ./mvnw -q package -DskipTests)
fi

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

Note: the Quarkit MCP server listens on 8080, so run the migrated todo app on 8090
(see demo/README.md, block e). Podman or Docker must be running for its Dev Services MySQL.
EOF
