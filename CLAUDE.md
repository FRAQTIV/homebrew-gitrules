# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a Homebrew tap repository for `gitrules-mcp`, providing a Homebrew formula to install an MCP (Model Context Protocol) server that exposes git rules and workflow tools. The tap enables users to install the package via `brew tap fraqtiv/gitrules` and `brew install gitrules-mcp`.

## Key Commands

### Release Management
- **Update formula for new version**: `./scripts/update-formula.sh v<version>` - Updates Formula/gitrules-mcp.rb with new version URL and SHA256 hash
- **Audit formula**: `brew audit --strict gitrules-mcp` - Validates formula compliance with Homebrew standards
- **First-time audit**: `brew audit --new-formula --strict fraqtiv/gitrules/gitrules-mcp` - Use for initial formula submission

### Manual SHA256 Calculation
```bash
VERSION=v0.3.1
BASE=https://github.com/FRAQTIV/gitrules-mcp-server/archive/refs/tags
curl -L -s "${BASE}/${VERSION}.tar.gz" -o /tmp/gitrules-mcp-${VERSION}.tar.gz
shasum -a 256 /tmp/gitrules-mcp-${VERSION}.tar.gz | awk '{print $1}'
```

## Repository Structure

- `Formula/gitrules-mcp.rb` - Homebrew formula definition for the MCP server
- `scripts/update-formula.sh` - Automation script for updating formula version and SHA256
- Standard Homebrew tap structure following `homebrew-<name>` convention

## Formula Architecture

The formula builds a Node.js-based MCP server from source:
1. Downloads tarball from GitHub releases
2. Runs `npm install` and `npm run build` 
3. Installs to libexec with all files
4. Creates executable script `mcp-git-rules` pointing to `dist/index.js`
5. Test verifies the binary starts and outputs JSON with `api_version`

## Workflow

1. Tag release in upstream project (FRAQTIV/gitrules-mcp-server)
2. Run `./scripts/update-formula.sh v<version>` to update formula
3. Run `brew audit --strict gitrules-mcp` to validate
4. Commit and push - users can then `brew upgrade gitrules-mcp`