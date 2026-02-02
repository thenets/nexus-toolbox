CREATED: AAP-62907
TITLE: [UI] Data Layer for Execution Visualization

## **Description**

Create the complete data layer for execution visualization including TypeScript types, state management, and data fetching hooks.

This story covers:
- TypeScript type definitions for nodes, edges, and WebSocket messages
- JSON Patch utility functions for applying activity updates
- Zustand store for execution visualization state
- Edge status derivation from node states
- REST API hooks for initial data fetching
- WebSocket hooks for real-time streaming with replay support

Data flow architecture:
- REST API provides initial execution data and workflow definition
- WebSocket streams activity state updates using JSON Patch format
- Zustand store manages all visualization state
- Edge status is derived client-side from source node status

## **Acceptance Criteria**

- TypeScript types defined for all visualization entities (nodes, edges, messages)
- JSON Patch utility functions handle add/replace/remove operations
- Zustand store manages execution visualization state immutably
- Edge status hook derives edge states from source node status
- REST hook fetches execution with `?include=workflow_definition,activities`
- WebSocket hook connects to /ws/workflows/v1/executions/{executionId}?replay=0
- WebSocket hook handles `initial_snapshot`, `activity_patch`, and `final_snapshot` message types
- Auto-reconnection with replay from last `event_id`
- Connection status (connected, stale) tracked in store
- UI correctly displays stream from `workflow-stream-demo.py --server`
- Unit tests for utilities, store actions, edge derivation, and hooks
- Integration tests for WebSocket connection lifecycle

## **Definition of Done**
- All type definitions created and exported
- JSON Patch utilities implemented with error handling
- Zustand store created with Immer middleware
- Edge status derivation hook implemented
- REST hook fetches and transforms execution data
- WebSocket hook streams updates in real-time
- Auto-reconnection works with event replay
- Hooks properly cleanup on unmount
- Unit tests for all utilities and hooks
- Integration tests for WebSocket lifecycle

## **Technical Notes**

**Files to Create:**
- packages/nexus-ui/src/routes/automations/execution/types.ts
- packages/nexus-ui/src/routes/automations/execution/utils/activityState.ts
- packages/nexus-ui/src/routes/automations/stores/useExecutionStore.ts
- packages/nexus-ui/src/routes/automations/hooks/useEdgeStatus.ts
- packages/nexus-ui/src/routes/automations/hooks/useExecutionData.ts
- packages/nexus-ui/src/routes/automations/hooks/useExecutionWebSocket.ts

**Test Files to Create:**
- packages/nexus-ui/src/routes/automations/execution/utils/activityState.test.ts
- packages/nexus-ui/src/routes/automations/stores/useExecutionStore.test.ts
- packages/nexus-ui/src/routes/automations/hooks/useEdgeStatus.test.ts
- packages/nexus-ui/src/routes/automations/hooks/useExecutionData.test.ts
- packages/nexus-ui/src/routes/automations/hooks/useExecutionWebSocket.test.ts

**Files to Modify:**
- packages/nexus-ui/src/routes/automations/canvas/nodes/nodeMetadata.ts - Change key from `aap` to `aap_job_template`

**Type Definitions:**
```
type NodeStatus = 'pending' | 'running' | 'success' | 'error' | 'skipped' | 'cancelled';
type EdgeStatus = 'pending' | 'passed';

interface JsonPatchOperation {
  op: 'add' | 'replace' | 'remove';
  path: string;
  value?: unknown;
}
```

**Store Structure:**
```
interface ExecutionStore {
  executionId: string | null;
  visualization: ExecutionVisualization | null;
  activityStates: Map<string, NodeStatus>;
  activityErrors: Map<string, string>;
  isConnected: boolean;
  isStale: boolean;
  isComplete: boolean;  // Set true on final_snapshot
  error: Error | null;
}
```

**Edge Derivation Rules:**
```
function deriveEdgeStatus(sourceStatus: NodeStatus): EdgeStatus {
  const passedStatuses = ['success', 'error', 'cancelled'];
  return passedStatuses.includes(sourceStatus) ? 'passed' : 'pending';
}
```

**WebSocket Message Handling:**
```
switch (message.type) {
  case 'initial_snapshot':
    // Full state on connection - initialize visualization
    store.setExecution(message.execution);
    lastEventId = message.event_id;
    break;
  case 'activity_patch':
    // Incremental update - apply JSON Patch operations
    applyJsonPatch(state, message.ops);
    lastEventId = message.event_id;
    break;
  case 'final_snapshot':
    // Execution complete - verify and finalize state
    store.setExecution(message.execution);
    store.setComplete(true);
    lastEventId = message.event_id;
    break;
}
```

**Reconnection Strategy:**
1. On disconnect, set `isStale = true`
2. Attempt reconnection with exponential backoff (1s, 2s, 4s, 8s, max 30s)
3. On reconnect, use `?replay=<lastEventId>` to resume from last known state
4. On successful reconnect, set `isStale = false`

## **References**

Related Stories:
- AAP-58247: Parent epic - Visualize Workflow Execution
- Story 1: Backend REST API Extension (provides `include` parameter)
- Story 2: Backend WebSocket Streaming (provides WebSocket endpoint)

Technical References:
- See specs/024-execution-visualizer/workflow-stream-demo.py for reference WebSocket protocol
- Use `workflow-stream-demo.py --server` to validate WebSocket hook implementation
- See data-model.md Sections 4, 10.3, 10.4 for schemas
- See quickstart.md Steps 1-2 for implementation guidance
