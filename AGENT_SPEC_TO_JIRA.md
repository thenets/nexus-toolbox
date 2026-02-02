# Agent: Spec to Jira

Convert Nexus project specifications into Jira epics and stories.

## Glossary

| Term | Definition |
|------|------------|
| **Jira file** | A local `.md` file in the `./jira/` directory containing ticket content in Markdown format |
| **Jira ticket** | An actual ticket created on the https://issues.redhat.com/ instance via MCP |

---

## Goal

Navigate a spec directory from the Nexus project and generate:
- **1 Epic** for the entire spec
- **Multiple Stories** derived from tasks in `tasks.md`

## Input

A spec directory path, e.g.:
```
/home/luiz/projects/nexus/nexus/specs/<spec-name>
```

## Output

Files written to:
```
./jira/<spec-name>/
├── epic.md
├── story-1-<description>.md
├── story-2-<description>.md
├── story-3-<description>.md
└── ...
```

---

## Workflow

### Step 1: Gather Context from Jira

Before generating content, **always check Jira for existing context**:

```
# Check if epic already exists
mcp__jira-mcp__jira_search(jql="project = AAP AND issuetype = Epic AND summary ~ 'spec-name'")

# Check for related tickets mentioned in the spec
mcp__jira-mcp__jira_get_issue(issue_key="AAP-XXXXX")
```

Use this context to:
- Avoid duplicate epics
- Reference existing parent epics
- Understand related work and dependencies

**If an existing epic or story is found:**
1. **ASK the user** what to do:
   - Use existing ticket (add ticket number to file header, read for context)
   - Create new ticket anyway
   - Skip this ticket
2. If using existing ticket:
   - Add `EXISTING: AAP-XXXXX` as the first line of the `.md` file
   - Read the existing ticket description for additional context
   - Generate content normally (will replace existing ticket in future)
3. If creating new: proceed as normal

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
- `## **Background**` - Primary user story in "As an X, I want Y, so that Z" format + context
- `## **User Stories**` - Maximum 3 supporting user stories
- `## **Acceptance Criteria**` - Scenario-based acceptance criteria

**Epic content sources:**
- Title: From spec.md header or overview
- Background: Primary user story from spec.md
- User Stories: Supporting user stories from spec.md (limit to 3 most important)
- Acceptance Criteria: From spec.md acceptance scenarios (use Scenario format)

### Step 4: Generate Stories

Create `story-N-<description>.md` files based on **phases** in `tasks.md` using the template from `_templates/story.md`.

**Splitting rules:**
- 1 story per phase (e.g., "Phase B2: REST API Extension")
- If a phase has >5 complex tasks, split into multiple stories
- **Backend and Frontend are ALWAYS separate stories**

**Story title format:**
- Backend: `[Backend] Phase description`
- Frontend: `[UI] Phase description`

**Required sections:**
- `## **Description**` - Problem statement, context, and proposed solution
- `## **Acceptance Criteria**` - Testable criteria for completion

**Optional sections** (include when they add value):
- `## **Technical Design**` - Component architecture and capabilities
- `## **Definition of Done**` - Completion checklist
- `## **Technical Notes**` - Files to create/modify, key considerations
- `## **Questions & Risks**` - Open questions and risk mitigation
- `## **Additional Context**` - Background information
- `## **References**` - Related stories and technical documentation

**NOTE:** Stories should contain only high-level details. Do NOT include a `## **Tasks**` section with granular implementation steps. File paths go in Technical Notes.

### Step 5: Create Issues in Jira

After user reviews and approves the `.md` files, create issues using MCP:

```python
# Create story with all required fields
mcp__jira-mcp__jira_create_issue(
    project_key="AAP",
    summary="[Backend] Story Title",
    issue_type="Story",
    description="<description content WITHOUT acceptance criteria>",
    components="nexus",
    additional_fields={
        "customfield_12311140": "AAP-XXXXX",           # Epic Link (parent epic)
        "customfield_12315940": "<acceptance criteria>", # AC field (Jira wiki markup!)
        "customfield_12319275": [{"value": "Project Nexus"}]  # Team
    }
)
```

After creation, add `CREATED: AAP-XXXXX` to the top of the `.md` file.

**IMPORTANT: Custom Fields Use Jira Wiki Markup**

The MCP API only converts Markdown to Jira wiki for the `description` field. Custom fields like `customfield_12315940` (Acceptance Criteria) must use **Jira wiki markup directly**:

```python
# CORRECT - Jira wiki markup for custom fields
additional_fields={
    "customfield_12315940": " * Criterion 1\n * Criterion 2\n * Criterion 3"
}

# WRONG - Markdown will NOT be converted for custom fields
additional_fields={
    "customfield_12315940": " * Criterion 1\n * Criterion 2\n * Criterion 3"  # This would work
    # But " - Criterion 1" (Markdown list) would NOT be converted
}
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

1. **Section headers**: Use `h2. *Title*` for main sections
2. **No italic**: Never use `_italic_` or `{_}text{_}` - always bold
3. **List prefixes**: Use `{*}Label{*}:` for bold labels in lists
4. **Simple lists**: Plain text without bold for straightforward items (Definition of Done, file lists)
5. **Code in lists**: Use `{{code}}` without bold wrapper in simple lists
6. **Emphasized code**: Use `*{{code}}*` when code needs emphasis in prose
7. **No over-formatting**: Keep Business Value and simple lists plain text

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

When text contains curly braces or slashes (common in API paths, file paths), use plain text - no bold, italic, or backticks. The MCP converter has issues with these characters inside formatting:
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
 * **As a** developer,
**I want** feature X,
**So that** benefit Y.

## **Description**

Current Problems:
 * **Multiple requests**: Description here
 * **Latency**: Another description

**Proposed Solution:**

Add `include` query parameter to `GET /api/v1/executions/{id}`:
 * `?include=workflow_definition` - Returns workflow structure
 * `?include=activities` - Returns activity states

## **Definition of Done**
 * `ExecutionRead` schema extended
 * `include` parameter implemented

## **Technical Notes**

Files to Modify:
 * `src/path/file.py` - Description
```

---

## Rules

### CRITICAL
1. **NEVER create Jira tickets without user confirmation** - Only generate `.md` files first
2. **Use Jira MCP for data gathering only** until user approves creation
3. **One epic per spec** - Never create multiple epics for the same spec
4. **Separate backend and frontend** - Always use clear prefixes: `[Backend]` or `[UI]`
5. **Acceptance Criteria in custom field** - NOT in description when creating via MCP
6. **Custom fields use Jira wiki markup** - Only description field gets Markdown conversion
7. **Only use supported language identifiers in code blocks** - Jira supports: actionscript, ada, applescript, bash, c, c#, c++, cpp, css, erlang, go, groovy, haskell, html, java, javascript, js, json, lua, none, nyan, objc, perl, php, python, r, rainbow, ruby, scala, sh, sql, swift, visualbasic, xml, yaml. Use ` ``` ` (no identifier) for unsupported languages like `typescript` or `tsx`

### Epic Requirements
- **Required**: Background (with user story format), User Stories (max 3), Acceptance Criteria (scenario format)
- Keep epics concise - they define scope, not implementation details

### Story Requirements
- **Required**: Description, Acceptance Criteria
- **Optional**: Technical Design, Definition of Done, Technical Notes, Questions & Risks, Additional Context, References
- Only include optional sections when they add clear value
- Remove the "OPTIONAL SECTIONS" notice from the template before output
- **NO Tasks section** - keep stories high-level, file paths go in Technical Notes
- **Testing is part of each story** - Include unit and integration tests in each story's acceptance criteria and technical notes. Do NOT create dedicated testing stories.

### Story Grouping
- Group work by phase from `tasks.md`
- Respect dependencies documented in the spec
- Keep stories high-level - no granular task lists
- File paths go in Technical Notes section only

### Content Quality
- Use imperative voice for tasks ("Create", "Implement", "Add")
- Include specific file paths from the spec
- Reference task IDs (B001, F001, etc.) when available
- Link to related Jira tickets found during context gathering
- **Always use bold inline code**: `*{{code}}*` not `{{code}}`

---

## Jira Custom Fields Reference

When creating issues via MCP, use these field mappings:

| Field | ID / Key | Value Format | Required |
|-------|----------|--------------|----------|
| Epic Link | `customfield_12311140` | `"AAP-XXXXX"` | Yes |
| Acceptance Criteria | `customfield_12315940` | Text with Jira markup | Yes |
| Team/Product Area | `customfield_12319275` | `[{"value": "Project Nexus"}]` | Yes |
| Component | `components` (in fields) | `"nexus"` or via update `[{"name": "nexus"}]` | Yes |
| Story Points | `customfield_12310243` | `3.0` (numeric) | No |

### Creating a Story - Full Example

```python
# Step 1: Create the issue
mcp__jira-mcp__jira_create_issue(
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

### Field Placement Rules

| Content | Where it goes |
|---------|---------------|
| Description, Tasks, Technical Design, Definition of Done, etc. | `description` field |
| Acceptance Criteria | `customfield_12315940` (separate field) |
| Epic parent | `customfield_12311140` |
| Team | `customfield_12319275` |
| Component | `components` parameter or update after creation |

---

## Example Invocation

```
User: Create Jira tickets for /home/luiz/projects/nexus/nexus/specs/<spec-name>

Agent:
1. Check Jira for existing epic (search for related tickets)
2. Read spec.md, tasks.md, plan.md, data-model.md
3. Generate:
   - ./jira/<spec-name>/epic.md
   - ./jira/<spec-name>/story-1-<description>.md
   - ./jira/<spec-name>/story-2-<description>.md
   - ./jira/<spec-name>/story-3-<description>.md
   - ...
   (Note: Testing is included in each story, not as separate stories)
4. Present summary to user for review
5. After approval, create each story in Jira with:
   - Epic Link to parent epic
   - Component: nexus
   - Team: Project Nexus
   - Acceptance Criteria in customfield_12315940 (Jira wiki markup)
6. Update .md files with CREATED: AAP-XXXXX
```

---

## Templates Location

Reference templates are available at:
- `_templates/epic.md` - Epic format template
- `_templates/story.md` - Story format template
