# Agent: Jira

Instructions for working with Jira files and Jira tickets for the Nexus project.

## Glossary

| Term | Definition |
|------|------------|
| **Jira file** | A local `.md` file in the `./jira/` directory containing ticket content in Markdown format |
| **Jira ticket** | An actual ticket on the https://issues.redhat.com/ instance managed via MCP |

---

## General Principles

- **Local files are the working copy** — edit `.md` files first, then sync to Jira
- **Never create Jira tickets without user confirmation** — generate `.md` files first
- **Use Jira MCP for data gathering freely** — read tickets, search, get fields anytime
- **Acceptance Criteria goes in a custom field** — NOT in the description field

---

## File Header Conventions

Use these headers at the top of `.md` files to track ticket status:

| Header | Meaning | Example |
|--------|---------|---------|
| `EXISTING: AAP-XXXXX` | Ticket already exists, content not yet synced | `EXISTING: AAP-12345` |
| `CREATED: AAP-XXXXX` | Ticket created in Jira from this file | `CREATED: AAP-12345` |
| `PARENT: ANSTRAT-YYYY` | Epic is linked to this parent Feature | `PARENT: ANSTRAT-1844` |

Example epic.md header after creation:
```
CREATED: AAP-64620
PARENT: ANSTRAT-1844

# Epic Title
```

---

## Jira Text Formatting Reference

### Headings
```
h2. *Section Title*     ← Bold section title (preferred)
h2. Section Title       ← Plain section title
h3. Subsection
```

### Bold Text
```
*bold text*             ← Standalone bold
{*}bold{*}              ← Inline bold within text
*Proposed Solution:*    ← Bold label with colon
```

### Monospace/Code
```
{{code}}                ← Simple monospace (use in lists, Definition of Done)
*{{code}}*              ← Bold monospace (use for emphasis)
{*}{{code}}{*}          ← Inline bold monospace in list items
```

### Lists with Bold Prefixes
```
Current Problems:
 * {*}Multiple requests{*}: Description here
 * {*}Latency{*}: Another description

Files to Modify:
 * {{src/path/file.py}} - Description
```

### User Story Format
```
h2. *User Story*
 * *As a* developer,
*I want* feature X,
*So that* benefit Y.
```

### Subsection Labels (No h3)
```
*Proposed Solution:*

Text here...

*What This Enables:*

Text here...
```

### Technical Design Numbered Items
```
1. *ComponentName* Schema Extension

Description...

2. Include Parameter Implementation

Description...
```

### Important Callouts
```
*IMPORTANT: The {{field}} must align with...*
```

### Code Blocks
```
{noformat}
preformatted text
{noformat}

{code:python}
def example():
    pass
{code}
```

### Links
```
[Link text|https://url.com]
AAP-12345               ← Auto-links to Jira ticket (no brackets needed)
```

### Tables
```
||Header 1||Header 2||Header 3||
|Cell 1|Cell 2|Cell 3|
|Cell 4|Cell 5|Cell 6|
```

### Style Guidelines

- **Section headers**: Use `h2. *Title*` for main sections
- **No italic**: Never use `_italic_` or `{_}text{_}` — always bold
- **List prefixes**: Use `{*}Label{*}:` for bold labels in lists
- **Simple lists**: Plain text without bold for straightforward items (Definition of Done, file lists)
- **Code in lists**: Use `{{code}}` without bold wrapper in simple lists
- **Emphasized code**: Use `*{{code}}*` when code needs emphasis in prose
- **No over-formatting**: Keep Business Value and simple lists plain text

---

## MCP API Formatting (IMPORTANT)

The Jira MCP tool (`mcp-atlassian`) converts **Markdown to Jira wiki markup** automatically via `_markdown_to_jira` for the `description` field only. This means:

| You send (Markdown) | API converts to (Jira) |
|---------------------|------------------------|
| `## **Title**` | `h2. *Title*` |
| `**bold**` | `*bold*` |
| `*italic*` | `_italic_` |
| `` `code` `` | `{{code}}` |
| ```` ``` ```` | `{code}` |

### Syntax by Field Type

| Field Type | Syntax to Use | Conversion |
|------------|---------------|------------|
| `description` | Markdown | Auto-converted to Jira wiki |
| Custom fields (e.g., Acceptance Criteria) | Jira wiki markup | No conversion |

### Local Files Use Markdown

Local `.md` files use **Markdown syntax** for consistency:
- Easier to read and edit
- Same format used for API `description` field
- When creating tickets, convert Acceptance Criteria to Jira wiki for custom field

**IMPORTANT: Never use numbered lists**

The Jira MCP tool converts Markdown numbered lists (`1. item`) to Jira wiki `#` syntax, which Jira renders as `h1.` headings instead of numbered list items. This happens because `#` at the start of a line in Jira wiki is ambiguous between headings and numbered lists.

Always use bullet lists (`-`) instead of numbered lists, even when describing sequential steps:
```markdown
# WRONG - renders as h1. headings in Jira
1. First step
2. Second step
3. Third step

# CORRECT - renders as bullet list
- First step
- Second step
- Third step
```

For sub-steps, use nested bullets:
```markdown
# WRONG - sub-numbered lists also break
- Parent item:
  1. Sub-step one
  2. Sub-step two

# CORRECT - nested bullets
- Parent item:
  - Sub-step one
  - Sub-step two
```

**IMPORTANT: Use hyphens for lists, not asterisks**

The MCP converter gets confused when asterisk lists contain bold text:
```markdown
# WRONG - causes mangled output
 * **As a** developer...

# CORRECT - converts cleanly
- **As a** developer...
```

The pattern ` * **text**` creates ambiguity with multiple asterisks. Using `- **text**` avoids this and converts correctly to ` * *text*` in Jira wiki.

**IMPORTANT: No formatting for strings containing `{`, `}`, or `/`**

When text contains curly braces or slashes (common in API paths, file paths), use plain text — no bold, italic, or backticks. The MCP converter has issues with these characters inside formatting:
```markdown
# WRONG - causes formatting issues
`GET /api/v1/executions/{id}`   →  broken nested braces
**GET /api/v1/executions/{id}** →  parsing issues with {id}

# CORRECT - use plain text
GET /api/v1/executions/{id}     →  renders correctly as plain text
```

### Markdown Syntax for API Calls (description field)

When calling `jira_create_issue` or `jira_update_issue`, use Markdown for description:

```markdown
## **User Story**

- **As a** developer,
- **I want** feature X,
- **So that** benefit Y.

## **Description**

Current Problems:
- **Multiple requests**: Description here
- **Latency**: Another description

**Proposed Solution:**

Add `include` query parameter to GET /api/v1/executions/{id}:
- `?include=workflow_definition` - Returns workflow structure
- `?include=activities` - Returns activity states

## **Definition of Done**

- `ExecutionRead` schema extended
- `include` parameter implemented

## **Technical Notes**

Files to Modify:
- `src/path/file.py` - Description
```

---

## Jira Custom Fields Reference

When creating issues via MCP, use these field mappings:

| Field | ID / Key | Value Format | Required |
|-------|----------|--------------|----------|
| Epic Name | `customfield_12311141` | `"Epic Title"` | Yes (Epics only) |
| Epic Link | `customfield_12311140` | `"AAP-XXXXX"` | Yes (Stories only) |
| Acceptance Criteria | `customfield_12315940` | Text with Jira markup | Yes |
| Team/Product Area | `customfield_12319275` | `[{"value": "Project Nexus"}]` | Yes |
| Component | `components` (in fields) | `"nexus"` or via update `[{"name": "nexus"}]` | Yes |
| Story Points | `customfield_12310243` | `3.0` (numeric) | No |

### Field Placement Rules

| Content | Where it goes |
|---------|---------------|
| Description, Tasks, Technical Design, Definition of Done, etc. | `description` field |
| Acceptance Criteria | `customfield_12315940` (separate field) |
| Epic parent | `customfield_12311140` |
| Team | `customfield_12319275` |
| Component | `components` parameter or update after creation |

---

## Creating Issues

### Creating an Epic — Full Example

```python
# Step 1: Create the epic
mcp__jira__jira_create_issue(
    project_key="AAP",
    summary="Epic Title Here",
    issue_type="Epic",
    description="## **Background**\n\n...<Markdown content>...\n\n## **User Stories**\n\n...",
    components="nexus",
    additional_fields={
        "customfield_12311141": "Epic Title Here",  # Epic Name (REQUIRED for epics!)
        "customfield_12315940": "h2. Acceptance Criteria\n\n*Scenario:* ...",  # Jira wiki!
        "customfield_12319275": [{"value": "Project Nexus"}]
    }
)

# Step 2: Link epic to parent Feature (if applicable)
mcp__jira__jira_create_issue_link(
    link_type="Incorporates",
    inward_issue_key="AAP-XXXXX",   # The new epic
    outward_issue_key="ANSTRAT-YYYY" # The parent Feature
)
# Result: Feature "incorporates" Epic, Epic "is incorporated by" Feature

# Step 3: Update local file with created ticket ID
# Add these lines to top of epic.md:
# CREATED: AAP-XXXXX
# PARENT: ANSTRAT-YYYY
```

**IMPORTANT: Epic Name Field**

Epics require the `customfield_12311141` (Epic Name) field. This is separate from `summary` and must be provided or the API will return an error: "Epic Name is required."

### Creating a Story — Full Example

```python
# Step 1: Create the issue
mcp__jira__jira_create_issue(
    project_key="AAP",
    summary="[Backend] Story Title Here",
    issue_type="Story",
    description="## **Description**\n\n...<Markdown content without AC>...",
    components="nexus",
    additional_fields={
        "customfield_12311140": "AAP-XXXXX",  # Parent epic
        "customfield_12315940": " * Criterion 1\n * Criterion 2\n * Criterion 3",  # Jira wiki!
        "customfield_12319275": [{"value": "Project Nexus"}]
    }
)

# Step 2: Update local file with created ticket ID
# Add "CREATED: AAP-XXXXX" to top of .md file
```

**IMPORTANT: Custom Fields Use Jira Wiki Markup**

The MCP API only converts Markdown to Jira wiki for the `description` field. Custom fields like `customfield_12315940` (Acceptance Criteria) must use **Jira wiki markup directly**:

```python
# CORRECT - Jira wiki markup for custom fields
additional_fields={
    "customfield_12315940": " * Criterion 1\n * Criterion 2\n * Criterion 3"
}

# WRONG - Markdown lists will NOT be converted for custom fields
additional_fields={
    "customfield_12315940": "- Criterion 1\n- Criterion 2\n- Criterion 3"
    # This renders as plain text, NOT as a list!
}
```

---

## Updating Issues

When syncing a local `.md` file to an existing Jira ticket:

```python
# Update description (use Markdown — auto-converted)
mcp__jira__jira_update_issue(
    issue_key="AAP-XXXXX",
    fields={
        "description": "## **Description**\n\n...<full Markdown content>..."
    }
)

# Update acceptance criteria (use Jira wiki markup — NOT auto-converted)
mcp__jira__jira_update_issue(
    issue_key="AAP-XXXXX",
    fields={},
    additional_fields={
        "customfield_12315940": " * Updated criterion 1\n * Updated criterion 2"
    }
)
```

### Syncing Local Files to Jira

When updating a Jira ticket from a local `.md` file:
- Read the `.md` file for the latest content
- Split content: description sections go in `description`, acceptance criteria goes in `customfield_12315940`
- Convert acceptance criteria from Markdown (local file format) to Jira wiki markup
- Verify after update by fetching the ticket

### Syncing Jira to Local Files

When a Jira ticket has been updated and the local file needs to catch up:
- Fetch the ticket via MCP
- Convert Jira wiki markup back to Markdown for the local file
- Update the `.md` file while preserving the header (`CREATED: AAP-XXXXX`)

---

## Reviewing and Searching

### Check for Existing Tickets

```python
# Search by summary keyword
mcp__jira__jira_search(jql="project = AAP AND issuetype = Epic AND summary ~ 'keyword'")

# Get full ticket details
mcp__jira__jira_get_issue(issue_key="AAP-XXXXX")

# Find stories under an epic
mcp__jira__jira_search(jql="project = AAP AND 'Epic Link' = AAP-XXXXX")
```

### When Existing Tickets Are Found

- **ASK the user** what to do:
  - Use existing ticket (add ticket number to file header, read for context)
  - Create new ticket anyway
  - Skip this ticket
- If using existing ticket:
  - Add `EXISTING: AAP-XXXXX` as the first line of the `.md` file
  - Read the existing ticket description for additional context

---

## Rules

### CRITICAL
- **NEVER create Jira tickets without user confirmation** — Only generate `.md` files first
- **Use Jira MCP for data gathering only** until user approves creation
- **Separate backend and frontend** — Always use clear prefixes: `[Backend]` or `[UI]`
- **Acceptance Criteria in custom field** — NOT in description when creating via MCP
- **Custom fields use Jira wiki markup** — Only description field gets Markdown conversion
- **Only use supported language identifiers in code blocks** — Jira supports: actionscript, ada, applescript, bash, c, c#, c++, cpp, css, erlang, go, groovy, haskell, html, java, javascript, js, json, lua, none, nyan, objc, perl, php, python, r, rainbow, ruby, scala, sh, sql, swift, visualbasic, xml, yaml. Use ` ``` ` (no identifier) for unsupported languages like `typescript` or `tsx`
- **Never use numbered lists** — Jira MCP converts `1. item` to `#` which renders as `h1.` headings. Always use bullet lists (`-`) instead, even for sequential steps
- **Use hyphens not asterisks** — `- item` not `* item` to avoid bold text mangling

### Content Quality
- Use imperative voice for tasks ("Create", "Implement", "Add")
- Include specific file paths from the spec
- Reference task IDs (B001, F001, etc.) when available
- Link to related Jira tickets found during context gathering
- Use backticks for inline code in Markdown files: `` `code` ``

---

## Workflow: Spec to Jira

Convert Nexus project specifications into Jira epics and stories.

### Input

A spec directory path, e.g.:
```
/home/luiz/projects/nexus/nexus/specs/<spec-name>
```

### Output

Files written to:
```
./jira/<spec-name>/
├── epic.md
├── story-1-<description>.md
├── story-2-<description>.md
├── story-3-<description>.md
└── ...
```

### Step 1: Gather Context from Jira

Before generating content, **always check Jira for existing context**:

```python
# Check if epic already exists
mcp__jira__jira_search(jql="project = AAP AND issuetype = Epic AND summary ~ 'spec-name'")

# Check for related tickets mentioned in the spec
mcp__jira__jira_get_issue(issue_key="AAP-XXXXX")
```

Use this context to:
- Avoid duplicate epics
- Reference existing parent epics
- Understand related work and dependencies

### Step 2: Read the Spec

Read these files from the spec directory:

| File | Purpose |
|------|---------|
| `spec.md` | Overview, requirements, user stories |
| `tasks.md` | Implementation tasks organized by phases |
| `plan.md` | Technical approach (if exists) |
| `data-model.md` | Data structures (if exists) |

### Step 3: Generate Epic

Create `epic.md` using the template from `_templates/epic.md`.

**Required sections:**
- `## **Background**` — Primary user story in "As an X, I want Y, so that Z" format + context
- `## **User Stories**` — Maximum 3 supporting user stories
- `## **Acceptance Criteria**` — Scenario-based acceptance criteria

**Epic content sources:**
- Title: From spec.md header or overview
- Background: Primary user story from spec.md
- User Stories: Supporting user stories from spec.md (limit to 3 most important)
- Acceptance Criteria: From spec.md acceptance scenarios (use Scenario format)

### Step 4: Generate Stories

Create `story-N-<description>.md` files based on **phases** in `tasks.md` using the template from `_templates/story.md`.

**Splitting rules:**
- One story per phase (e.g., "Phase B2: REST API Extension")
- If a phase has >5 complex tasks, split into multiple stories
- **Backend and Frontend are ALWAYS separate stories**

**Story title format:**
- Backend: `[Backend] Phase description`
- Frontend: `[UI] Phase description`

**Required sections:**
- `## **Description**` — Problem statement, context, and proposed solution
- `## **Acceptance Criteria**` — Testable criteria for completion

**Optional sections** (include when they add value):
- `## **Technical Design**` — Component architecture and capabilities
- `## **Definition of Done**` — Completion checklist
- `## **Technical Notes**` — Files to create/modify, key considerations
- `## **Questions & Risks**` — Open questions and risk mitigation
- `## **Additional Context**` — Background information
- `## **References**` — Related stories and technical documentation

**NOTE:** Stories should contain only high-level details. Do NOT include a `## **Tasks**` section with granular implementation steps. File paths go in Technical Notes.

### Step 5: Create Issues in Jira

After user reviews and approves the `.md` files, create issues using the examples in the "Creating Issues" section above. After creation, add `CREATED: AAP-XXXXX` to the top of the `.md` file.

### Spec-to-Jira Rules

- **One epic per spec** — Never create multiple epics for the same spec
- **Testing is part of each story** — Include unit and integration tests in each story's acceptance criteria and technical notes. Do NOT create dedicated testing stories.
- **No Tasks section** — Keep stories high-level, file paths go in Technical Notes
- Remove the "OPTIONAL SECTIONS" notice from the template before output

### Story Grouping
- Group work by phase from `tasks.md`
- Respect dependencies documented in the spec
- Keep stories high-level — no granular task lists
- File paths go in Technical Notes section only

### Example Invocation

```
User: Create Jira tickets for /home/luiz/projects/nexus/nexus/specs/<spec-name>

Agent:
- Check Jira for existing epic (search for related tickets)
- Read spec.md, tasks.md, plan.md, data-model.md
- Generate:
  - ./jira/<spec-name>/epic.md
  - ./jira/<spec-name>/story-1-<description>.md
  - ./jira/<spec-name>/story-2-<description>.md
  - ./jira/<spec-name>/story-3-<description>.md
  - ...
  (Note: Testing is included in each story, not as separate stories)
- Present summary to user for review
- After approval, create each story in Jira with:
  - Epic Link to parent epic
  - Component: nexus
  - Team: Project Nexus
  - Acceptance Criteria in customfield_12315940 (Jira wiki markup)
- Update .md files with CREATED: AAP-XXXXX
```

---

## Templates Location

Reference templates are available at:
- `_templates/epic.md` — Epic format template
- `_templates/story.md` — Story format template
