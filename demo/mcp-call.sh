#!/usr/bin/env bash
# Calls the quarkit MCP server over HTTP (stateless MCP, protocol 2026-07-28).
#
# Usage:
#   ./mcp-call.sh tools/list
#   ./mcp-call.sh tools/call <tool-name> '<arguments as JSON>'
#
# Examples:
#   ./mcp-call.sh tools/list | jq -r '.result.tools[].name'
#   ./mcp-call.sh tools/call quarkit_reference_lookup '{"map":"annotation","key":"@Transactional","mode":"compat"}' \
#     | jq -r '.result.content[0].text'
#
# MCP_URL overrides the endpoint (default http://localhost:8080/mcp).
set -euo pipefail

METHOD=${1:?usage: mcp-call.sh tools/list | tools/call <tool> '<json>'}
NAME=${2:-}
ARGS=${3:-'{}'}
MCP_URL=${MCP_URL:-http://localhost:8080/mcp}

META='"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/clientInfo":{"name":"curl","version":"1.0"},"io.modelcontextprotocol/clientCapabilities":{}}'

if [ "$METHOD" = "tools/call" ]; then
  BODY="{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"$NAME\",\"arguments\":$ARGS,$META}}"
  NAME_HEADER=(-H "Mcp-Name: $NAME")
else
  BODY="{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$METHOD\",\"params\":{$META}}"
  NAME_HEADER=()
fi

curl -s "$MCP_URL" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'MCP-Protocol-Version: 2026-07-28' \
  -H "Mcp-Method: $METHOD" "${NAME_HEADER[@]+"${NAME_HEADER[@]}"}" \
  -d "$BODY"
