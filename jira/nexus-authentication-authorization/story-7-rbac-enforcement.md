## **Description**

All Nexus API endpoints must enforce role-based access control with a deny-by-default policy. Users have one of three roles (USER, AUDITOR, ADMIN) synced from AAP, and each endpoint must verify the user has appropriate permissions.

**Current State:**
- Users have roles synced from AAP (from previous stories)
- Endpoints are not protected by role checks
- No permission enforcement mechanism

**Proposed Solution:**

Implement RBAC enforcement:
- Deny-by-default middleware for all endpoints
- Define explicit permission requirements per endpoint
- Create reusable permission dependencies
- Apply role checks to all API endpoints

## **Acceptance Criteria**

- Deny-by-default: all endpoints require authentication unless explicitly public
- All /api/v1/* endpoints require valid access token (401 if missing/invalid)
- Permission denied returns 403 with clear error message
- Role permissions (explicit, not hierarchical):
  - **ADMIN**: Full access - create/edit/delete any resource, manage users/sessions, view all logs
  - **AUDITOR**: Read-only access - view all resources and auth/authz logs, CANNOT create/edit/delete or run workflows
  - **USER**: Create/own/edit/delete own resources, run workflows, view execution logs (NOT auth logs)
- Ownership checks for USER role (can only modify own resources)
- Permission dependencies reusable across endpoints
- Unit tests for each role's permissions
- Integration tests verifying access control on key endpoints

## **Technical Design**

**1. Role Permissions (Explicit - No Hierarchy)**

Each role has explicit capabilities. Roles are NOT hierarchical.

| Role | Capabilities |
|------|--------------|
| **ADMIN** | Full access: create/edit/delete any resource, manage users/sessions, view all logs, panic button |
| **AUDITOR** | Read-only: view all resources and auth/authz logs. Cannot create/edit/delete or run workflows |
| **USER** | Create/own/edit/delete own resources, run workflows, view execution logs (not auth logs) |

**2. Permission Dependencies**

FastAPI dependencies for common permission patterns:

- `get_current_user` - Validates access token, returns current user (in `src/nexus/api/auth/dependencies.py`)
- `require_role(*roles)` - Checks user has one of specified roles
- `require_admin` - Shorthand for require_role(ADMIN)
- `require_owner_or_admin(resource)` - Checks user owns resource or is admin

**3. Endpoint Protection Matrix**

| Resource | USER | AUDITOR | ADMIN |
|----------|------|---------|-------|
| View workflows | ✓ | ✓ | ✓ |
| Create workflow | ✓ | ✗ | ✓ |
| Edit own workflow | ✓ | ✗ | ✓ |
| Edit others' workflow | ✗ | ✗ | ✓ |
| Delete own workflow | ✓ | ✗ | ✓ |
| Delete others' workflow | ✗ | ✗ | ✓ |
| Run workflow | ✓ | ✗ | ✓ |
| View execution logs | ✓ | ✓ | ✓ |
| View auth/authz logs | ✗ | ✓ | ✓ |
| Manage users/sessions | ✗ | ✗ | ✓ |
| Panic button | ✗ | ✗ | ✓ |

**4. Public Endpoints (No Auth Required)**

- `GET /health` - Health check
- `GET /ready` - Readiness probe
- `GET /auth/login` - Initiate OAuth flow
- `GET /auth/callback` - OAuth callback
- `GET /auth/.well-known/jwks.json` - JWKS for token verification
- `GET /openapi.json` - OpenAPI schema

## **Definition of Done**

- Deny-by-default middleware implemented
- Permission dependencies implemented
- All endpoints decorated with appropriate permission checks
- Ownership validation for user resources
- 401 returned for missing/invalid tokens
- 403 returned for insufficient permissions
- All permission combinations tested
- Code reviewed and merged

## **Technical Notes**

**Files to Create:**
- `src/nexus/api/auth/middleware.py` - Deny-by-default authorization enforcement
- `src/nexus/api/auth/dependencies.py` - get_current_user and permission dependencies

**Files to Modify:**
- `src/nexus/api/routes/*.py` - Add permission dependencies to all endpoints

**Key Considerations:**
- Use FastAPI Depends() for clean permission injection
- Middleware validates token on every request (except public endpoints)
- Cache user lookup from token claims to avoid repeated DB queries
- Ownership check must query database to verify resource.owner_id == user.id
- Log `access_denied` events to auth_events table

## **References**

Related Stories:
- AAP-64620: Nexus Authentication and Authorization (Epic)

Technical References:
- [FastAPI Security Dependencies](https://fastapi.tiangolo.com/tutorial/security/)
- [OWASP Access Control Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Access_Control_Cheat_Sheet.html)
