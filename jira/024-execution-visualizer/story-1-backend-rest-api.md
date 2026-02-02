CREATED: AAP-62895
TITLE: [Backend] REST API Extension for Execution Visualization

## **User Story**
- **As a** frontend developer,
**I want** the execution API to return workflow definition and activity states in a single call,
**So that** I can render the execution visualization without multiple API requests.

## **Description**

Currently, the frontend must make multiple API calls to gather all data needed to render the execution visualization. This creates unnecessary latency and complexity.

Current Problems:
- **Multiple requests**: Frontend needs separate calls for execution, workflow definition, and activity states
- **Latency**: Each additional request adds network round-trip time
- **Complexity**: Frontend must coordinate multiple async calls and handle partial failures

**Proposed Solution:**

Add `include` query parameter to GET /api/v1/executions/{id} that allows clients to request additional data in a single call:
- `?include=workflow_definition` - Returns the workflow structure for graph rendering
- `?include=activities` - Returns current activity execution states
- `?include=workflow_definition,activities` - Returns both in one request

**What This Enables:**

This API extension establishes:
- Single request for all visualization data
- Consistent schema between REST and WebSocket (Story 2)
- Backward compatibility with existing clients

Business Value:
- Faster page load: Single request instead of multiple
- Simpler frontend: No coordination of multiple async calls
- Better UX: Reduced latency for visualization rendering

## **Acceptance Criteria**

- When `?include=workflow_definition` is passed, the response includes the full workflow definition
- When `?include=activities` is passed, the response includes activity execution data with status, timestamps, and error details
- When no `include` parameter is passed, the response remains unchanged (backward compatible)
- Multiple includes can be combined: `?include=workflow_definition,activities`
- Unit tests cover all include parameter combinations
- Integration tests verify API response structure

## **Technical Design**

1. **ExecutionRead** Schema Extension

Extend `ExecutionRead` with optional fields:
- **workflow_definition**: Full workflow JSON when requested
- **activities**: Array of activity states when requested

2. Include Parameter Implementation

Add `include` query parameter to `get_execution()` endpoint:
- Parse comma-separated values
- Validate against allowed values
- Conditionally fetch and include requested data

## **Shared Schema**

**IMPORTANT: The `activities` array schema returned by this API MUST align exactly with the schema used by WebSocket `initial_snapshot` and `final_snapshot` messages in Story 2 (Backend Valkey Streams). This ensures the UI can process REST and WebSocket data uniformly.**

See specs/024-execution-visualizer/test-workflow-events.json for the complete schema example.
```json
"activities": [
  {
    "activity_name": "fetch_data",
    "status": "pending",
    "error_details": null,
    "started_at": null,
    "completed_at": null
  },
  {
    "activity_name": "validate_input",
    "status": "pending",
    "error_details": null,
    "started_at": null,
    "completed_at": null
  }
]
```

## **Definition of Done**
- `ExecutionRead` schema extended with optional fields
- `include` query parameter implemented and documented
- OpenAPI spec updated to reflect new parameters
- All existing tests pass without modification
- Unit tests for include parameter logic
- Integration tests for API endpoint

## **Technical Notes**

Files to Modify:
- src/nexus/workflows/models/execution.py - Add `ActivityData` model and extend `ExecutionRead`
- src/nexus/api/v1/executions.py - Add `include` query parameter to `get_execution()`

Test Files to Create:
- tests/unit/api/v1/test_executions_include.py - Unit tests for include parameter parsing and schema validation
- tests/integration/api/v1/test_executions_visualization.py - Integration tests for API response structure

## **References**

Related Stories:
- AAP-58247: Parent epic - Visualize Workflow Execution
- Story 2: [Backend] Valkey Streams and WebSocket - MUST use same `activities` schema

Technical References:
- See specs/024-execution-visualizer/test-workflow-events.json for complete schema example
- See data-model.md Section 10.2 for schema details
