# Claude Code Tools

MCP server configurations for Claude Code.

## Jira Integration

Add the `mcp-atlassian` server to interact with Jira:

```bash
claude mcp add mcp-atlassian uvx mcp-atlassian -e JIRA_URL=https://issues.redhat.com -e JIRA_PERSONAL_TOKEN='${JIRA_PERSONAL_TOKEN}'
```

### Prerequisites

1. Set the `JIRA_PERSONAL_TOKEN` environment variable with your Jira personal access token
2. Ensure `uvx` is available (installed via `uv` or `pipx`)

### Available Operations

- Search issues with JQL
- Get issue details
- Create/update issues
- Manage sprints and boards
- Add comments and worklogs
