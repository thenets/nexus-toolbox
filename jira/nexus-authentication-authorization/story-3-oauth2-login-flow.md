CREATED: AAP-65190

## **Description**

Users need to authenticate via AAP Gateway's OAuth2 endpoints and receive Nexus JWT tokens. This flow must fetch user profile and roles from the Gateway API and sync them to the Nexus database.

**Current State:**
- JWT infrastructure exists (from previous story)
- No OAuth2 integration with AAP Gateway
- No user sync from AAP

**Proposed Solution:**

Implement the complete OAuth2 login flow:
- Login initiation redirects to AAP Gateway
- Callback exchanges code for AAP access token
- Fetch user profile from /api/gateway/v1/me/
- Map AAP roles (is_superuser, is_auditor) to Nexus roles
- Create/update user in database
- Issue Nexus JWT tokens with secure delivery

## **Acceptance Criteria**

- GET /auth/login redirects to AAP OAuth2 authorization URL with state parameter
- GET /auth/callback exchanges code for AAP access token
- User profile fetched from AAP Gateway /api/gateway/v1/me/ endpoint
- Role mapping (ADMIN takes precedence if both flags set):
  - `is_superuser=true` → ADMIN
  - `is_auditor=true` → AUDITOR
  - default → USER
- User created in database if new (matched by `aap_user_id`), updated if existing
- User model extended with `aap_user_id` field (unique per non-deleted users)
- Access token returned in response body (stored in client memory)
- Refresh token set via HTTP-only, Secure, SameSite=Strict cookie
- State parameter validated on callback (CSRF protection)
- POST /auth/logout implements front-channel logout:
  1. Revokes refresh token from Redis
  2. Clears HTTP-only cookie
  3. Redirects to AAP logout endpoint
  4. AAP terminates session and redirects back to Nexus login page
- GET /auth/me returns current user info from token
- Integration tests with mocked AAP Gateway responses

## **Technical Design**

**1. OAuth2 Flow Endpoints**

| Endpoint | Method | Description |
|----------|--------|-------------|
| /auth/login | GET | Initiate OAuth redirect to AAP |
| /auth/callback | GET | OAuth callback, exchange code for tokens |
| /auth/logout | POST | Front-channel logout (Nexus + AAP) |
| /auth/me | GET | Returns current user info |

**2. AAP Gateway Integration**

**Capabilities:**
- Exchange authorization code at /o/token/
- Fetch user data from /api/gateway/v1/me/ with OAuth2 access token
- Handle AAP Gateway errors gracefully (show friendly error if AAP unavailable)

**3. User Sync**

**Capabilities:**
- Create user record with `aap_user_id` on first login
- Update username, email, full_name, user_type on subsequent logins
- No background sync - only during user's own login
- If user deleted in AAP: session continues until refresh token expires (max 8hrs)
- If user deleted then re-created with same email: new AAP ID prevents accidental reuse of old Nexus user record

## **Definition of Done**

- All auth endpoints implemented and tested
- OAuth2Provider fully implemented with AAP Gateway integration
- User sync working (create and update)
- Refresh token in HTTP-only cookie
- Access token in response body
- State parameter CSRF protection working
- Front-channel logout with AAP redirect working
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
- User profile endpoint: /api/gateway/v1/me/
- OAuth2 scope: read
- Cookie flags: HttpOnly, Secure, SameSite=Strict
- State parameter must be cryptographically random and validated
- Logout MUST redirect to AAP logout endpoint (front-channel logout)

## **References**

Related Stories:
- AAP-64620: Nexus Authentication and Authorization (Epic)

Technical References:
- [Authlib FastAPI Integration](https://docs.authlib.org/en/latest/client/fastapi.html)
- [OWASP OAuth2 Security](https://cheatsheetseries.owasp.org/cheatsheets/OAuth2_Cheat_Sheet.html)
