# Toolbox

Support repository for the [Nexus](../nexus/) project. Contains Jira ticket management, agent specs, and Claude Code tooling.

## Repository Structure

```
toolbox/
├── AGENT_JIRA.md             # Instructions for working with Jira files and tickets
├── _templates/               # Jira epic and story templates
├── jira/                     # Generated Jira ticket content (markdown files)
│   └── <spec-name>/          # One directory per Nexus spec
│       ├── epic.md
│       └── story-N-*.md
└── claude-tools/             # Claude Code configuration and utilities
```

## Jira Work

When working with Jira tickets — creating, updating, reviewing, or syncing stories — **always read `AGENT_JIRA.md` first**. It contains:

- General Jira formatting reference and known MCP pitfalls
- Custom field IDs and API field mappings
- Issue creation and update examples
- Spec-to-Jira workflow for converting Nexus specs into epics and stories
- Critical rules (no numbered lists, hyphens not asterisks, custom field markup)

## Nexus Specs

Specs live in the sibling repo at `/home/luiz/projects/nexus/nexus/specs/`. Each spec directory contains `spec.md`, `tasks.md`, `plan.md`, and `data-model.md`. These are the source of truth for Jira story content.

## Conventions

- Local `.md` files in `jira/` use Markdown syntax
- File headers track Jira ticket state: `CREATED: AAP-XXXXX`, `EXISTING: AAP-XXXXX`, `PARENT: ANSTRAT-YYYY`
- Backend stories use `[Backend]` prefix, frontend stories use `[Frontend]` or `[UI]` prefix
- Jira project: `AAP`, component: `nexus`, team: `Project Nexus`
