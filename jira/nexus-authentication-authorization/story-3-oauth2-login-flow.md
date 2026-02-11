CREATED: AAP-65190

## **Description**

Users need to authenticate via AAP Gateway's OAuth2 endpoints and receive Nexus JWT tokens. This is a two-phase flow: OAuth2 authentication followed by user data retrieval via Gateway REST API (AAP 2.6 does not support OIDC userinfo claims).

**Current State:**
- JWT infrastructure exists (from previous story)
- No OAuth2 integration with AAP Gateway
- No user sync from AAP

**Proposed Solution:**

Implement the complete OAuth2 authorization code flow:
- Login initiation redirects to AAP Gateway `/o/authorize/`
- Callback exchanges authorization code for AAP access token at `/o/token/`
- Fetch user profile from `/api/gateway/v1/me/` using AAP access token
- Map AAP role flags to Nexus roles
- Create/update user in database with `aap_user_id`
- Issue Nexus JWT tokens (AAP tokens are ephemeral — discarded after profile fetch)

## **Acceptance Criteria**

**Login Flow:**
- GET /auth/login generates cryptographically random state, stores it, and redirects to AAP `/o/authorize/` with `client_id`, `redirect_uri`, `scope=read`, `state`
- GET /auth/callback validates state parameter (CSRF protection), then:
  - Exchanges authorization code for AAP access token at `/o/token/` (HTTP Basic auth with client_id/client_secret)
  - Fetches user profile from `/api/gateway/v1/me/` using AAP access token
  - Creates or updates user in database (matched by `aap_user_id`)
  - Maps role flags (ADMIN takes precedence if both set):
     - `is_superuser=true` → ADMIN
     - `is_platform_auditor=true` → AUDITOR
     - default → USER
  - Issues Nexus JWT tokens with namespaced claims
  - Returns access token in JSON response body
  - Sets refresh token via `Set-Cookie: HttpOnly; Secure; SameSite=Strict`
- AAP tokens are ephemeral: used only for profile fetch, never stored

**Auth Events Logged:**
- `LOGIN_SUCCESS`: after successful login (metadata: `aap_user_id`, `aap_instance_id`, `role_assigned`)
- `LOGIN_FAILURE`: on any failure (metadata: `error_code`, `error_message`, `aap_instance_id`)
- `USER_CREATED`: on first login when new user record is created
- `ROLE_CHANGE`: when role synced from AAP differs from stored role (metadata: `old_role`, `new_role`)

**Login Failure Error Codes:**

| Error Code | Trigger |
|------------|---------|
| `csrf_mismatch` | State parameter does not match stored state |
| `code_exchange_failed` | AAP rejected the authorization code |
| `aap_unreachable` | AAP Gateway unreachable during code exchange or profile fetch |
| `profile_fetch_failed` | Code exchanged but user profile fetch failed |
| `oauth2_error` | AAP returned an error in callback (`?error=...` parameter) |

**User Sync:**
- User model extended with `aap_user_id` field (unique per non-deleted users)
- First login: create user record with `aap_user_id` (FR-002a)
- Subsequent logins: update username, email, full_name, user_type
- Username stored in `nexus/username` format: `<aap-instance-id>/<username>` (e.g., `aap-prod/john.doe`)
- No background sync — only during user's own login

**Logout Flow (Front-Channel):**
- POST /auth/logout:
  - Revokes refresh token from Redis
  - Clears HTTP-only cookie via expired `Set-Cookie`
  - Logs `LOGOUT` event
  - Returns AAP logout redirect URL: `https://<aap-gateway>/logout/?redirect_uri=<nexus-login-url>`
  - `redirect_uri` must match `post_logout_redirect_uris` in AAP OAuth2 app config
- Graceful degradation: if AAP unavailable, clear local tokens and redirect to Nexus login page

**Other Endpoints:**
- GET /auth/me returns user info from JWT claims: `id` (from `sub`), `username` (from `nexus/username`), `email`, `user_type` (from `nexus/user_type`)
- All auth error responses use RFC 9457 Problem Details format

**Integration tests with mocked AAP Gateway responses**

## **Technical Design**

**1. OAuth2 Flow Sequence**

```
Browser → GET /auth/login → Redirect to AAP /o/authorize/?client_id=...&state=...
Browser → AAP login page → User authenticates
AAP → Redirect to GET /auth/callback?code=...&state=...
Nexus → POST AAP /o/token/ (exchange code, Basic auth) → AAP access token
Nexus → GET AAP /api/gateway/v1/me/ (Bearer AAP token) → User profile
Nexus → Create/update user → Issue Nexus JWT tokens
Nexus → Response: { access_token } + Set-Cookie: refresh_token
```

**2. Token Transport Per Endpoint**

| Endpoint | Refresh Token | Access Token |
|----------|---------------|--------------|
| GET /auth/callback | **Response**: `Set-Cookie` (HttpOnly; Secure; SameSite=Strict) | **Response**: JSON body |
| POST /auth/refresh | **Request**: Sent via cookie | **Response**: JSON body |
| POST /auth/logout | **Response**: Clear cookie (expired `Set-Cookie`) | N/A |
| GET /auth/me | **Request**: Sent via cookie | **Request**: `Authorization: Bearer` header |

**3. AAP OAuth2 Application Requirements**

The AAP OAuth2 application must be configured:

| Field | Value | Purpose |
|-------|-------|---------|
| `client_type` | `confidential` | Server-side app with secure secret storage |
| `authorization_grant_type` | `authorization-code` | Standard OAuth2 web flow |
| `skip_authorization` | `true` | Skip approval screen for trusted first-party app |
| `redirect_uris` | Nexus callback URL | Must match exactly |
| `post_logout_redirect_uris` | Nexus login URL | Redirect destination after AAP logout |

**4. Re-authentication Experience**

| Scenario | AAP Session | User Experience |
|----------|-------------|-----------------|
| First login (`skip_authorization: true`) | N/A | AAP credentials only, no approval screen |
| Re-login (Nexus expired, AAP active) | Active | Silent redirect (no prompts) |
| Re-login (both expired) | Expired | AAP credentials only, no approval screen |

**5. Edge Cases**

| Scenario | Behavior |
|----------|----------|
| AAP unavailable during login | Show friendly error; user cannot authenticate |
| AAP unavailable during logout | Clear local tokens, redirect to Nexus login |
| User deleted in AAP | Session continues until refresh token expires (max 8hrs) |
| User role changed in AAP | Takes effect on next login (max 8h 15m delay) |
| User deleted then re-created (same email) | New `aap_user_id` prevents reuse of old Nexus record |

## **Definition of Done**

- All auth endpoints implemented and tested
- OAuth2Provider fully implemented with AAP Gateway integration
- User sync working (create and update, with role change detection)
- Refresh token in HTTP-only cookie
- Access token in JSON response body
- State parameter CSRF protection working
- Front-channel logout with AAP redirect working
- AuthEvent logging for login/logout/role-change events
- All auth errors return RFC 9457 Problem Details format
- Integration tests with mocked AAP responses passing
- Code reviewed and merged

## **Technical Notes**

**Files to Create:**
- `src/nexus/core/auth/services/auth_service.py` - Login/logout orchestration

**Files to Modify:**
- `src/nexus/core/auth/providers/oauth2.py` - Complete OAuth2Provider implementation
- `src/nexus/api/auth/router.py` - Add login, callback, logout, me endpoints
- `src/nexus/core/models/user.py` - Add aap_user_id column, update role enum to ADMIN/AUDITOR/USER

**Database Migration:**
- Add `aap_user_id` column to users table (unique per non-deleted users)
- Migrate existing roles from CREATOR/APPROVER/ADMINISTRATOR/VIEWER to ADMIN/AUDITOR/USER

**Key Considerations:**
- AAP Gateway OAuth2 endpoints: /o/authorize/, /o/token/
- AAP user profile endpoint: /api/gateway/v1/me/
- AAP logout endpoint: /logout/?redirect_uri=...
- OAuth2 scope: read
- Cookie flags: HttpOnly, Secure, SameSite=Strict
- State parameter must be cryptographically random and validated
- AAP tokens are ephemeral — used once for profile fetch, then discarded
- Username format: `<aap-instance-id>/<username>` (configurable via `AAP_INSTANCE_ID` setting)

## **References**

Related Stories:
- AAP-64620: Nexus Authentication and Authorization (Epic)

Technical References:
- [Authlib FastAPI Integration](https://docs.authlib.org/en/latest/client/fastapi.html)
- [OWASP OAuth2 Security](https://cheatsheetseries.owasp.org/cheatsheets/OAuth2_Cheat_Sheet.html)
