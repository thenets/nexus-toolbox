## **Description**

Administrators need visibility into active sessions and the ability to revoke them. The system must also log authentication events for security auditing and provide emergency revocation capabilities.

**Current State:**
- Sessions exist in Redis (from previous stories)
- No admin visibility into sessions
- No revocation capabilities beyond natural expiry
- No audit logging of auth events

**Proposed Solution:**

Implement session administration:
- User session list endpoint (view own sessions)
- Admin session management endpoints
- Per-user and global session revocation
- Panic button for emergency mass revocation
- Audit logging for all auth events

## **Acceptance Criteria**

- GET /api/v1/sessions returns current user's active sessions (jti, device, ip, issued_at, expires_in)
- DELETE /api/v1/sessions/{jti} revokes specific session (own sessions only)
- POST /api/v1/admin/users/{id}/revoke-tokens revokes all sessions for a user (admin only)
- POST /api/v1/admin/sessions/revoke-all activates panic button (admin only)
- Panic button sets global_revocation_timestamp in Redis
- Access token validation checks iat against global_revocation_timestamp
- GET /api/v1/admin/auth-events returns paginated audit log (admin and auditor only)
- GET /api/v1/admin/sessions/stats returns session statistics (admin only)
- Auth events logged with correct types (see schema below)
- All admin endpoints require ADMIN role (except auth-events which allows AUDITOR)
- Unit and integration tests for all endpoints

## **Technical Design**

**1. AuthEvent Model**

New database model for audit logging.

```
Fields:
- id: UUID (PK)
- user_id: UUID FK (nullable for failed logins)
- event_type: Enum (see below)
- ip_address: String (max 45 chars for IPv6)
- user_agent: String (max 1000 chars)
- metadata: JSON (event-specific context)
- created_at: Timestamp
```

**Event Types:**
- `login_success` - Successful authentication
- `login_failure` - Failed authentication attempt
- `logout` - User logged out
- `token_refresh` - Token was refreshed
- `token_revoked` - Token was revoked (single session)
- `access_denied` - Authorization check failed (403)
- `role_change` - User role changed during login sync
- `panic_revocation` - Panic button activated (all sessions revoked)

**2. Session Monitoring**

**Capabilities:**
- List user's sessions by scanning Redis for their tokens
- Show device, IP, creation time, remaining TTL
- Allow users to end specific sessions

**3. Admin Revocation**

**Capabilities:**
- Revoke all tokens for specific user (SCAN + DEL by user_id)
- Global panic button (set timestamp + delete all refresh tokens)
- Access tokens checked against global timestamp on every request
- Log `panic_revocation` event when panic button used

## **Definition of Done**

- AuthEvent model created with migration
- User session list and revoke endpoints working
- Admin revocation endpoints working
- Panic button functional with access token validation
- Audit logging capturing all specified events
- Admin audit log query endpoint with pagination
- Session statistics endpoint working
- All tests passing
- Code reviewed and merged

## **Technical Notes**

**Files to Create:**
- `src/nexus/core/models/auth_event.py` - AuthEvent model
- `src/nexus/core/auth/services/audit_service.py` - Audit event logging
- `src/nexus/api/routes/sessions.py` - Session management endpoints
- `src/nexus/api/routes/admin.py` - Admin endpoints

**Files to Modify:**
- `src/nexus/core/auth/services/token_service.py` - Add global_revocation_timestamp check
- `src/nexus/core/auth/services/session_service.py` - Add revocation methods
- Database migrations for auth_event table

**Key Considerations:**
- Use SCAN with MATCH pattern for Redis queries (never KEYS in production)
- Panic button should be rare - log prominently and alert
- Audit log should not block auth operations (async write if possible)
- Session stats useful for monitoring dashboards
- AUDITOR role can view auth-events but not manage sessions

## **References**

Related Stories:
- AAP-64620: Nexus Authentication and Authorization (Epic)

Technical References:
- [JWT Revocation Strategies](https://supertokens.com/blog/revoking-access-with-a-jwt-blacklist)
- [OWASP Logging Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html)
