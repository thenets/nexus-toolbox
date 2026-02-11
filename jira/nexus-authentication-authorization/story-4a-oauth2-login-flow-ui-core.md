EXISTING: AAP-65497

## **Description**

The Nexus SPA needs to handle the core OAuth2 authentication flow: initiating login, processing the callback redirect, managing basic auth state, and providing logout functionality. The backend handles all OAuth2 complexity (code exchange, token issuance); the frontend manages token storage, auth state, and user experience.

**Current State:**
- No login UI exists
- No OAuth2 redirect handling in the frontend
- No logout functionality

**Proposed Solution:**

Implement the core frontend OAuth2 flow:
- **Login Page** — Redirect user to backend `GET /auth/login`, which redirects to AAP Gateway
- **Callback Handler** — Process backend redirect after OAuth2 callback, extract access token from JSON response, refresh token arrives via `Set-Cookie`
- **Auth State Management** — Track authentication status and user info from namespaced JWT claims
- **Logout** — Call `POST /auth/logout`, clear local state, redirect to AAP logout URL returned by backend
- **Protected Routes** — Guard authenticated routes, redirect to login with return URL

## **Acceptance Criteria**

**Login Flow:**
- Login page with "Login with Ansible Automation Platform" button
- Button navigates to `GET /auth/login` (full page redirect)
- Backend redirects to AAP Gateway → user authenticates → AAP redirects to `GET /auth/callback`
- Backend exchanges code, issues Nexus JWT tokens, responds with:
  - Access token in JSON response body
  - Refresh token via `Set-Cookie: HttpOnly; Secure; SameSite=Strict`
- Frontend stores access token in memory only (NOT localStorage/sessionStorage)
- After login, user returned to their original destination (pre-login URL)
- With `skip_authorization: true` in AAP config, re-authentication is seamless (silent redirect when AAP session is still active)

**Auth State:**
- Auth context provides: `isAuthenticated`, `user` (from `/auth/me` or JWT decode), `logout()`
- User info includes: `id`, `username` (format: `<aap-instance-id>/<username>`), `email`, `user_type` (`ADMIN`/`AUDITOR`/`USER`)
- JWT claims use `nexus/` namespace: `nexus/username`, `nexus/user_type`, `nexus/token_type`
- Access token stored in JavaScript memory only — never persisted to disk
- Refresh token is HTTP-only cookie, invisible to JavaScript

**Logout Flow:**
- Call `POST /auth/logout`
- Backend revokes refresh token, clears HTTP-only cookie, returns AAP logout redirect URL
- Response: `{ "aap_logout_url": "https://<aap-gateway>/logout/?redirect_uri=<nexus-login-url>" }`
- Frontend clears local auth state (in-memory access token)
- Frontend redirects browser to `aap_logout_url`
- AAP terminates AAP session and redirects back to Nexus login page
- Graceful degradation: if backend returns no `aap_logout_url` (AAP unavailable), redirect to Nexus login page directly

**Protected Routes:**
- Unauthenticated users redirected to login page
- Original URL preserved for post-login redirect
- Loading state shown while checking auth status

**Error Handling:**
- Backend auth errors use RFC 9457 Problem Details format
- Display user-friendly error messages (never expose internal details)
- If AAP unavailable during login: show friendly error page with retry option
- If OAuth2 callback fails: show error with option to try again

## **Technical Design**

**- Login Page**

Simple page with login button. Full page redirect to `/auth/login`.

**Capabilities:**
- Display "Login with Ansible Automation Platform" button
- Navigate to `GET /auth/login` (backend handles OAuth2 redirect to AAP)
- Show loading state during redirect
- Display error message if redirected back with error query params

**- Callback Handler**

Route that processes the backend's response after OAuth2 callback completion.

**Flow:**
- Backend completes OAuth2 code exchange and issues Nexus JWT tokens
- Backend redirects/responds with access token in JSON body
- Frontend extracts access token, stores in memory
- Refresh token arrives as `Set-Cookie` (no JS interaction needed)
- Redirect user to original destination or dashboard

**Error Handling:**
- Parse RFC 9457 Problem Details from error responses
- Map error types to user-friendly messages
- Provide "Try again" action

**- Auth Context/Store**

Global state management for authentication.

**State:**

```
interface AuthState {
  isAuthenticated: boolean;
  user: {
    id: string;           // from JWT `sub` claim
    username: string;     // from JWT `nexus/username` claim
    email: string;        // from JWT `email` claim
    userType: string;     // from JWT `nexus/user_type` claim (ADMIN/AUDITOR/USER)
  } | null;
  accessToken: string | null;  // in-memory only
}
```

**Capabilities:**
- Decode user info from access token JWT claims (namespaced: `nexus/username`, `nexus/user_type`)
- Alternatively, fetch user info from `GET /auth/me` endpoint
- Expose `isAuthenticated` boolean
- Provide `logout()` function (calls `POST /auth/logout`, follows redirect)
- Persist auth state across page navigation (memory only — lost on full page reload)

**- Protected Route Guard**

Higher-order component/wrapper that enforces authentication on routes.

**Capabilities:**
- Redirect unauthenticated users to login page
- Preserve original URL for post-login redirect
- Show loading state while checking auth status

## **Definition of Done**

- Login page implemented with AAP branding
- Callback handler processing access token from JSON response correctly
- Auth context providing user state (with namespaced claims) to entire app
- Front-channel logout flow working (Nexus → POST /auth/logout → redirect to AAP logout → Nexus login)
- Protected routes redirecting to login with return URL
- All components tested
- Code reviewed and merged

## **Technical Notes**

**Files to Create:**
- `src/pages/Login.tsx` — Login page component
- `src/pages/AuthCallback.tsx` — OAuth2 callback handler
- `src/contexts/AuthContext.tsx` — Auth state management with namespaced JWT claims
- `src/components/ProtectedRoute.tsx` — Route guard for authenticated routes

**Key Considerations:**
- NEVER store access tokens in localStorage or sessionStorage (XSS risk)
- Access token only exists in JavaScript memory
- Refresh token is HTTP-only cookie, invisible to JavaScript — sent automatically on `POST /auth/refresh`
- JWT custom claims use `nexus/` namespace prefix (`nexus/username`, `nexus/user_type`, `nexus/token_type`)
- Username format: `<aap-instance-id>/<username>` (e.g., `aap-dev/john.doe`)
- Logout is front-channel: `POST /auth/logout` → follow `aap_logout_url` → AAP redirects back to Nexus login
- With `skip_authorization: true` in AAP OAuth2 app, re-authentication is seamless when AAP session is active (silent redirect, no prompts)
- Backend returns RFC 9457 Problem Details for all auth errors — frontend should parse and display

**Token Transport Per Endpoint (Frontend Perspective):**

| Endpoint | Refresh Token | Access Token |
|----------|---------------|--------------|
| GET /auth/callback | Received via `Set-Cookie` (automatic) | Received in JSON response body |
| POST /auth/logout | Cleared via expired `Set-Cookie` | N/A (client discards from memory) |
| GET /auth/me | Sent automatically via cookie | Sent via `Authorization: Bearer` header |
| Protected API calls | Sent automatically via cookie | Sent via `Authorization: Bearer` header |

## **References**

Related Stories:
- AAP-64620: Nexus Authentication and Authorization (Epic)
- AAP-65190: OAuth2 Login Flow (Backend) — dependency, implements the backend endpoints this story consumes
- Story 4b: Session Lifecycle & Token Refresh — builds on this story

Technical References:
- [OWASP Token Storage Best Practices](https://cheatsheetseries.owasp.org/cheatsheets/HTML5_Security_Cheat_Sheet.html#local-storage)
