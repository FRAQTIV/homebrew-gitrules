# FRAQTIV Homebrew Tap

Official Homebrew tap for FRAQTIV's git-related tools and MCP servers.

## About

This repository provides Homebrew formulas for installing FRAQTIV's git workflow tools, including the `gitrules-mcp` server - an assistant-agnostic MCP (Model Context Protocol) server that exposes git rules and workflow automation tools.

## Installation

First, add the tap to your Homebrew installation:

```bash
brew tap fraqtiv/gitrules https://github.com/FRAQTIV/homebrew-gitrules
```

Then install the available packages:

```bash
brew install gitrules-mcp
```

You can also install directly without adding the tap:

```bash
brew install fraqtiv/gitrules/gitrules-mcp
```

## Available Packages

### gitrules-mcp

An MCP (Model Context Protocol) server that provides git rules and workflow automation tools for AI assistants.

- **Homepage**: https://github.com/FRAQTIV/gitrules-mcp-server
- **Current Version**: v0.3.0
- **License**: MIT

## Development & Maintenance

### Releasing a New Version

1. **Tag release** in the upstream project (e.g., `v0.3.1`)
2. **Update formula** using the automation script:
   ```bash
   ./scripts/update-formula.sh v0.3.1
   ```
3. **Validate the formula**:
   ```bash
   brew audit --strict gitrules-mcp
   ```
4. **Commit and push** - users can then upgrade with `brew upgrade gitrules-mcp`

### Manual Formula Updates

If you need to manually update the SHA256 hash:

```bash
VERSION=v0.3.1
BASE=https://github.com/FRAQTIV/gitrules-mcp-server/archive/refs/tags
curl -L -s "${BASE}/${VERSION}.tar.gz" -o /tmp/gitrules-mcp-${VERSION}.tar.gz
shasum -a 256 /tmp/gitrules-mcp-${VERSION}.tar.gz | awk '{print $1}'
```

Then update the `url` and `sha256` fields in `Formula/gitrules-mcp.rb`.

## Testing

The formula includes a basic test that verifies the MCP server starts correctly and outputs JSON with an `api_version` field. You can test locally with:

```bash
brew test gitrules-mcp
```

## CI/CD

The repository includes GitHub Actions workflows that automatically test formula installations on macOS. Bottles (pre-compiled binaries) may be added in the future via `brew test-bot`.

## License

MIT - Same as the upstream projects.
