CREATED: AAP-62906
TITLE: [UI] Routing and Integration for Execution Visualization

## **Description**

Add routing configuration and navigation links to integrate the execution visualization page into the existing application.

This completes the frontend integration by:
- Adding a route for the execution visualization page
- Adding navigation links from workflow list to execution view
- Lazy loading the ExecutionPage component for performance

## **Acceptance Criteria**

- Route /executions/:executionId (or /automations/:workflowId/executions/:executionId) loads ExecutionPage
- ExecutionPage is lazy loaded
- Navigation link available from workflow list to view execution
- Execution status indicator visible in workflow list items
- Route parameters correctly passed to ExecutionPage
- Integration tests for routing and navigation

## **Definition of Done**
- Route configured and accessible
- Lazy loading working correctly
- Navigation links functional
- Route parameters handled correctly
- No broken links or 404s
- Browser back/forward navigation works
- Integration tests for routing

## **Technical Notes**

**Files to Modify:**
- packages/nexus-ui/src/app/AppRoute.tsx - Add execution visualization route
- packages/nexus-ui/src/routes/automations/Automations.tsx - Add navigation links

**Test Files to Create:**
- packages/nexus-ui/src/app/AppRoute.test.tsx - Integration tests for route navigation

**Route Options:**
- /executions/:executionId - Simple, but lacks workflow context
- /automations/:workflowId/executions/:executionId - Provides workflow context for breadcrumbs

**Lazy Loading:**
```
const ExecutionPage = lazy(() => import('./routes/automations/execution/ExecutionPage'));
```

## **References**

Related Stories:
- AAP-58247: Parent epic - Visualize Workflow Execution
- Story 5: UI Components (provides ExecutionPage)
