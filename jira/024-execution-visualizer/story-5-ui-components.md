CREATED: AAP-62908
TITLE: [UI] Execution Visualization Components

## **Description**

Create the React components for rendering the execution visualization including nodes, edges, canvas, header, and connection status banner.

Component hierarchy:
- `ExecutionPage` - Top-level page component
  - `ExecutionHeader` - Workflow name, status, elapsed time, stop button
  - `ExecutionCanvas` - ReactFlow canvas with custom node/edge types
    - `ExecutionNode` - Custom node with status badge
      - `StatusBadge` - Visual status indicator
    - `ExecutionEdge` - Custom edge with status styling
  - `ConnectionBanner` - Stale data warning

## **Acceptance Criteria**

- StatusBadge displays correct icon and color for each status (pending, running, success, error, skipped, cancelled)
- ExecutionNode renders node type icon and status badge
- ExecutionEdge shows dotted line for pending, solid line for passed
- ExecutionCanvas renders workflow graph with proper layout
- ExecutionHeader shows workflow info and elapsed time
- ConnectionBanner appears when connection is lost
- All components are read-only (no editing capabilities)
- Components correctly render stream from `workflow-stream-demo.py --server`
- Unit tests for all components covering all status values

## **Definition of Done**
- All components created and rendering correctly
- Status indicators match design specifications
- ReactFlow integration working with custom node/edge types
- Connection banner shows/hides based on connection status
- Stop automation button functional
- Components responsive and accessible
- Unit tests for all components

## **Technical Notes**

**Files to Create:**
- packages/nexus-ui/src/routes/automations/canvas/nodes/StatusBadge.tsx
- packages/nexus-ui/src/routes/automations/execution/ExecutionNode.tsx
- packages/nexus-ui/src/routes/automations/execution/ExecutionEdge.tsx
- packages/nexus-ui/src/routes/automations/execution/ExecutionCanvas.tsx
- packages/nexus-ui/src/routes/automations/execution/ExecutionHeader.tsx
- packages/nexus-ui/src/routes/automations/execution/ExecutionPage.tsx
- packages/nexus-ui/src/components/ConnectionBanner.tsx

**Test Files to Create:**
- packages/nexus-ui/src/routes/automations/canvas/nodes/StatusBadge.test.tsx - Unit tests for status icon rendering
- packages/nexus-ui/src/routes/automations/execution/ExecutionNode.test.tsx - Unit tests for node rendering
- packages/nexus-ui/src/routes/automations/execution/ExecutionCanvas.test.tsx - Unit tests for canvas layout

**Status Badge Colors:**

| Status | Border Color | Icon | Animation |
|--------|--------------|------|-----------|
| pending | gray | ellipsis | none |
| running | blue | spinner | spin |
| success | green | checkmark | none |
| error | red | exclamation | pulse |
| skipped | gray (dashed) | skip arrow | none |
| cancelled | orange | stop | none |

**ReactFlow Configuration:**
```
<ReactFlow
  nodes={nodes}
  edges={edges}
  nodeTypes={{ execution: ExecutionNode }}
  edgeTypes={{ execution: ExecutionEdge }}
  fitView
  nodesDraggable
  nodesConnectable={false}
  elementsSelectable
/>
```

## **References**

Related Stories:
- AAP-58247: Parent epic - Visualize Workflow Execution
- Story 4: UI Data Layer (provides store and hooks)

Technical References:
- Use `workflow-stream-demo.py --server` to validate component rendering with live WebSocket stream
- See specs/024-execution-visualizer/workflow-stream-demo.py for reference protocol (initial_snapshot, activity_patch, final_snapshot)
- See data-model.md Section 6 for component specifications
- See quickstart.md Steps 4-5 for implementation guidance
