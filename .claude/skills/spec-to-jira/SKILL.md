---
name: spec-to-jira
description: Use when converting Nexus project specifications into Jira epics and stories. Triggers on requests to create tickets from spec directories or generate epics/stories from specs.
---

# Spec to Jira

Convert Nexus project specifications into Jira epics and stories.

**Required:** Use the `jira` skill for MCP tools, formatting rules, and custom fields.

**Full reference:** See [AGENT_SPEC_TO_JIRA.md](../../../AGENT_SPEC_TO_JIRA.md) for complete workflow.

## Input

A spec directory path:
```
/home/luiz/projects/nexus/nexus/specs/<spec-name>
```

## Output

Local files in `./jira/<spec-name>/`:
```
epic.md
story-1-<description>.md
story-2-<description>.md
...
```

## Workflow

```
1. GATHER CONTEXT
   ├─ Search Jira: existing epic for this spec?
   └─ If found → ASK user: use existing, create new, or skip

2. READ SPEC
   ├─ spec.md (overview, user stories)
   ├─ tasks.md (phases, implementation tasks)
   ├─ plan.md (technical approach, if exists)
   └─ data-model.md (data structures, if exists)

3. GENERATE LOCAL FILES
   ├─ epic.md (1 per spec, from _templates/epic.md)
   └─ story-N-<desc>.md (1 per phase, from _templates/story.md)

   ⚠️  Do NOT create Jira tickets yet!

4. USER REVIEWS FILES
   └─ Wait for explicit approval

5. CREATE IN JIRA (after approval)
   ├─ Create epic first
   ├─ Create stories with epic link
   └─ Update .md files with CREATED: AAP-XXXXX
```

## Story Splitting Rules

- **1 story per phase** from tasks.md (e.g., "Phase B2: REST API")
- **Backend and Frontend ALWAYS separate**
  - Backend: `[Backend] Phase description`
  - Frontend: `[UI] Phase description`
- **>5 complex tasks?** Split into multiple stories
- **Testing included in each story** - No dedicated testing stories

## Epic Structure

From `_templates/epic.md`:

```markdown
## **Background**
**As an** X, **I want to** Y, **so that I can** Z.

<context>

## **User Stories**
- As an X, I want to Y. (max 3)

## **Acceptance Criteria**
**Scenario:** Name
- **Given** precondition
- **When** action
- **Then** result
```

## Story Structure

From `_templates/story.md`:

**Required sections:**
- `## **Description**` - Problem, context, solution
- `## **Acceptance Criteria**` - Testable criteria

**Optional sections** (include when valuable):
- `## **Technical Design**`
- `## **Definition of Done**`
- `## **Technical Notes**` - Files to create/modify
- `## **Questions & Risks**`
- `## **References**`

**NO `## Tasks` section** - Keep stories high-level.

## Critical Rules

1. **NEVER create Jira tickets without user approval**
2. **One epic per spec**
3. **Backend/Frontend always separate**
4. **AC in custom field, not description** (when creating via MCP)
5. **Reference task IDs** (B001, F001) when available
