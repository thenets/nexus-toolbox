CREATED: AAP-62905
TITLE: [Backend] Valkey Streams and WebSocket Streaming

## **Description**

Implement real-time activity status streaming using Valkey Streams as the message broker between Temporal workers and API servers, with WebSocket endpoints for frontend consumption.

Architecture Context:
- `ActivitySyncService` runs on Temporal worker processes
- WebSocket connections live on API server processes
- Valkey Streams bridge this process boundary and enable event replay for reconnection

**Proposed Solution:**

Create a publish-subscribe system where:
1. `ActivitySyncService` publishes activity state changes to Valkey Streams after database commits
2. WebSocket handler subscribes to streams and forwards events to connected clients
3. Clients can request replay from a specific event ID for reconnection scenarios

## **Acceptance Criteria**

- Activity state changes are published to Valkey Stream execution:{execution_id}:events after database commit
- WebSocket endpoint /api/v1/ws/executions/{executionId} streams activity updates to clients
- Clients receive `initial_snapshot` on connection with full execution state
- Clients receive `activity_patch` messages with JSON Patch operations for incremental updates
- Clients receive `final_snapshot` when execution completes, enabling state verification
- Clients can use `?replay=0` to receive all events from the beginning
- Clients can use `?replay=<event_id>` to resume from a specific point
- Heartbeat messages are sent every 30 seconds when no updates occur
- The specs/024-execution-visualizer/workflow-stream-viewer.py can connect and display the stream correctly
- Unit tests cover publisher, WebSocket handler, and message schemas
- Integration tests verify end-to-end WebSocket streaming with replay

## **Technical Design**

**1. ActivityUpdatePublisher**

Publishes activity changes to Valkey Streams using XADD:
- Stream key: execution:{execution_id}:events
- Message format: JSON Patch with `type`, `execution_id`, `event_id`, `ops[]`

**2. WebSocket Handler**

Follow auto-discovery convention with:
- `handle_activityUpdates()` - Server-to-client channel handler
- `on_connect_activityUpdates()` - Connection setup with Valkey XREAD consumer
- Support replay parameter for reconnection

## **Definition of Done**
- Valkey Streams publisher created and integrated with `ActivitySyncService`
- WebSocket endpoint functional with replay support
- Message schemas defined and validated (initial_snapshot, activity_patch, final_snapshot, heartbeat)
- Protocol supports state verification: initial_snapshot → activity_patch* → final_snapshot
- Heartbeat mechanism working
- Unit tests for publisher and message schemas
- Integration tests for WebSocket streaming end-to-end
- workflow-stream-viewer.py connects and validates stream correctly

## **Technical Notes**

**Files to Create:**
- src/nexus/workflows/services/activity_update_publisher.py
- src/nexus/workflows/ws/execution_streaming.py
- src/nexus/workflows/schemas/visualization.py

**Files to Modify:**
- src/nexus/workflows/workflow_engine/services/activity_sync_service.py - Integrate publisher after `session.commit()`

**Test Files to Create:**
- tests/unit/workflows/test_activity_update_publisher.py - Unit tests for publisher message formatting
- tests/unit/workflows/test_visualization_schemas.py - Unit tests for message schema validation
- tests/integration/workflows/test_execution_visualization_ws.py - Integration tests for WebSocket streaming and replay

**Message Types:**

**1. initial_snapshot** - Full state on first connection (replay=0):
```json
{
  "type": "initial_snapshot",
  "execution_id": "abc-123-def-456",
  "event_id": "1691431234000-0",
  "timestamp": "2025-12-10T15:30:00Z",
  "execution": {
    "execution_id": "abc-123-def-456",
    "workflow_id": "test-workflow-001",
    "status": "pending",
    "activities": [
      {"activity_name": "fetch_data", "status": "pending", ...}
    ]
  }
}
```

**2. activity_patch** - Incremental updates via JSON Patch:
```json
{
  "type": "activity_patch",
  "execution_id": "abc-123-def-456",
  "event_id": "1691431234100-1",
  "timestamp": "2025-12-10T15:30:01Z",
  "ops": [
    {"op": "replace", "path": "/activities/0/status", "value": "running"}
  ]
}
```

**3. final_snapshot** - Full state after all patches applied (for verification):
```json
{
  "type": "final_snapshot",
  "execution_id": "abc-123-def-456",
  "event_id": "1691431234100-15",
  "timestamp": "2025-12-10T15:31:00Z",
  "execution": {
    "execution_id": "abc-123-def-456",
    "workflow_id": "test-workflow-001",
    "status": "completed",
    "activities": [
      {"activity_name": "fetch_data", "status": "completed", ...}
    ]
  }
}
```

**4. heartbeat** - Keep-alive:
```json
{"type": "heartbeat", "timestamp": "2025-12-10T15:30:00Z"}
```

**Replay Behavior:**
- No parameter: Read only new events (BLOCK on stream)
- `replay=0`: Read from beginning (initial_snapshot + all patches + final_snapshot)
- `replay=<event_id>`: Read from that event_id onwards

## **Shared Schema**

**IMPORTANT:** The `initial_snapshot` and `final_snapshot` messages use the same `Execution` schema as REST API GET /executions/{id}?include=activities. This enables unified UI processing for both WebSocket and REST data sources.

The `final_snapshot` allows clients to verify that applying all `activity_patch` operations produces the expected final state.

## **References**

Related Stories:
- AAP-58247: Parent epic - Visualize Workflow Execution
- Story 1: [Backend] REST API Extension - MUST use same `activities` schema

Technical References:
- See specs/024-execution-visualizer/workflow-stream-demo.py for the reference WebSocket protocol implementation
- See specs/024-execution-visualizer/workflow-stream-viewer.py for validation - the viewer MUST connect successfully to the backend implementation
- See quickstart.md Steps 2-3 for implementation details
- See data-model.md Sections 3.1, 9.5, 10.3 for schemas
