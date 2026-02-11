---
name: jira
description: Use when creating, updating, or reading Jira tickets and local jira files. Triggers on any Jira MCP operations, editing ./jira/*.md files, or working with AAP project tickets.
---

# Jira Operations

Reference for Jira ticket operations via MCP and local jira file management.

**Full reference:** See [AGENT_SPEC_TO_JIRA.md](../../../AGENT_SPEC_TO_JIRA.md) for complete formatting guide.

## Quick Reference

| Item | Value |
|------|-------|
| Project | `AAP` |
| Component | `nexus` |
| Team | `Project Nexus` |
| Jira files | `./jira/<feature>/` |

## Formatting Rules

| Field | Format | Conversion |
|-------|--------|------------|
| `description` | Markdown | Auto-converted to Jira wiki |
| Custom fields (AC, etc.) | Jira wiki | No conversion |
| Local `.md` files | Markdown | For readability |

### Markdown (for description and local files)

```markdown
## **Section Title**

- **Bold item**: Description here
- `inline code` for file paths

**Subsection:**

Content here with [links](https://example.com).
```

**Use `-` for lists, NOT `*`** - avoids conflicts with bold `**text**`.

### Jira Wiki (for custom fields only)

```
h2. *Section Title*

 * *Bold item*: Description here
 * {{inline code}} for file paths

*Subsection:*

Content here with [links|https://example.com].
```

### Formatting Gotchas

- **No formatting for `{`, `}`, `/`** - Use plain text for API paths like `GET /api/v1/executions/{id}`
- **Code blocks:** Use ` ``` ` without language identifier for unsupported languages (typescript, tsx)
- **Supported languages:** python, javascript, js, json, bash, sh, java, go, yaml, xml, sql, html, css

## MCP Tools

### Search & Read

```python
# Search issues
mcp__jira__jira_search(
    jql="project = AAP AND component = nexus AND status = 'In Progress'",
    fields="summary,status,assignee",
    limit=20
)

# Get issue details
mcp__jira__jira_get_issue(
    issue_key="AAP-XXXXX",
    fields="summary,description,customfield_12315940"
)

# Get available transitions
mcp__jira__jira_get_transitions(issue_key="AAP-XXXXX")
```

### Create Issues

```python
# Create Epic
mcp__jira__jira_create_issue(
    project_key="AAP",
    summary="Epic Title",
    issue_type="Epic",
    description="<Markdown content>",
    components="nexus",
    additional_fields={
        "customfield_12311141": "Epic Title",  # Epic Name (REQUIRED!)
        "customfield_12315940": " * AC 1\n * AC 2",  # Jira wiki!
        "customfield_12319275": [{"value": "Project Nexus"}]
    }
)

# Create Story
mcp__jira__jira_create_issue(
    project_key="AAP",
    summary="[Backend] Story Title",
    issue_type="Story",
    description="<Markdown content>",
    components="nexus",
    additional_fields={
        "customfield_12311140": "AAP-XXXXX",  # Epic Link
        "customfield_12315940": " * AC 1\n * AC 2",  # Jira wiki!
        "customfield_12319275": [{"value": "Project Nexus"}]
    }
)
```

### Update & Link

```python
# Update issue
mcp__jira__jira_update_issue(
    issue_key="AAP-XXXXX",
    fields={"summary": "New Title", "description": "<Markdown>"}
)

# Add comment
mcp__jira__jira_add_comment(
    issue_key="AAP-XXXXX",
    comment="Comment in Markdown format"
)

# Transition issue
mcp__jira__jira_transition_issue(
    issue_key="AAP-XXXXX",
    transition_id="21"  # Get from jira_get_transitions
)

# Link issues
mcp__jira__jira_create_issue_link(
    link_type="Blocks",
    inward_issue_key="AAP-111",
    outward_issue_key="AAP-222"
)

# Link epic to parent feature
mcp__jira__jira_create_issue_link(
    link_type="Incorporates",
    inward_issue_key="AAP-XXXXX",   # Epic
    outward_issue_key="ANSTRAT-YYYY"  # Parent feature
)
```

## Custom Fields

| Field | ID | Format |
|-------|-----|--------|
| Epic Name | `customfield_12311141` | String (required for epics) |
| Epic Link | `customfield_12311140` | Issue key string |
| Acceptance Criteria | `customfield_12315940` | Jira wiki text |
| Team | `customfield_12319275` | `[{"value": "Project Nexus"}]` |
| Story Points | `customfield_12310243` | Float (e.g., `3.0`) |

## File Headers

Track ticket status in local `.md` files:

```
CREATED: AAP-XXXXX    # Ticket created from this file
EXISTING: AAP-XXXXX   # Existing ticket found, not yet synced
PARENT: ANSTRAT-YYYY  # Epic linked to parent feature
```

## Templates

- Epic: `_templates/epic.md`
- Story: `_templates/story.md`
