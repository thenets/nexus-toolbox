EXISTING: AAP-58247

## **Background**

**As an** Operator, **I want to** see a real-time, interactive graph of my entire workflow, **so that I can** visually monitor its progress and health at a glance.

This epic delivers the core "single pane of glass" for operators. It focuses on rendering the workflow as an interactive graph and providing immediate, real-time visual feedback on the status of each step, enabling users to "see" the automation as it happens.

## **User Stories**
- As an Operator, I want to see my workflow displayed as a graph of nodes connected by edges, so that I can understand the complete flow of tasks.
- As an Operator, I want to see a unique icon for each node type (agent, API, AAP job template, script, condition, loop, converge), so that I can quickly distinguish between different kinds of steps.
- As an Operator, I want to see the status of each node (running, success, error, pending, skipped, cancelled) update in real-time, so that I can immediately identify where the workflow is and if it's healthy.

## **Acceptance Criteria**

**Scenario:** Render the workflow graph
- **Given** I am viewing the runtime page for a specific workflow
- **When** the page loads
- **Then** I should see the entire workflow rendered as a graph of nodes and connecting edges.

**Scenario:** Display node types
- **Given** the workflow graph is rendered
- **When** I look at any node
- **Then** I should see a distinct icon that indicates its type (agent, API, script, etc).

**Scenario:** Real-time status updates
- **Given** a node is running
- **When** its state changes to "success" or "error"
- **Then** its icon must update to reflect the new status without page refresh.

**Scenario:** Edge transition visualization
- **Given** a node successfully passes data to the next
- **When** the transition is complete
- **Then** the edge connecting them should change from dotted to solid white.

**Scenario:** Connection loss handling
- **Given** I am viewing an active workflow
- **When** the connection to the status update stream is lost
- **Then** I should see a warning indicating that the displayed data may not reflect current state.

**Scenario:** Connection recovery
- **Given** the connection was lost and a warning is displayed
- **When** the connection is restored
- **Then** the warning should be removed and the visualization should resync to current state.
