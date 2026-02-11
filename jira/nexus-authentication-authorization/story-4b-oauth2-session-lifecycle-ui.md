CREATED: AAP-65515

## **Description**

With the core authentication flow in place (story 4a), the frontend needs session lifecycle management: proactive token refresh to keep sessions alive, a session expiry modal for when refresh fails (FR-020), and multi-tab awareness. Without this, users would be logged out as soon as their 15-minute access token expires.

**Current State (after story 4a):**
- Login, callback, and logout flows working
- Auth context tracks user state and access token in memory
- No token refresh — session dies when access token expires
- No session expiry handling

**Proposed Solution:**

Layer session resilience onto the existing auth context:
- **Proactive Token Refresh** — Call `POST /auth/refresh` before access token expires, update in-memory token seamlessly
- **Session Expiry Modal (FR-020)** — Show non-blocking dialog when refresh fails, no auto-redirect, user clicks to re-authenticate
- **Multi-Tab Support** — Each tab independently detects expiry and shows modal, preserving page context

## **Acceptance Criteria**

**Token Refresh:**
- Frontend calls `POST /auth/refresh` before access token expires (proactive refresh)
- Refresh token sent automatically via cookie
- New access token returned in JSON response body, stored in memory
- On refresh failure (401), trigger session expiry modal (do not auto-redirect)
- Refresh scheduling resets after each successful refresh

**Session Expiry (FR-020):**
- When access token expires and refresh fails, show a modal dialog: "Your session has expired. Please log in again."
- Modal must NOT auto-redirect — user clicks to re-authenticate
- In multi-tab scenarios, each tab independently detects expiry and shows modal
- Modal preserves current page context (user can re-authenticate and continue where they were)
- "Log In" button navigates to `/auth/login` (preserving return URL)

**Integration with Auth Context:**
- Token refresh logic integrated into `AuthContext.tsx` from story 4a
- Session expiry detection triggers modal overlay without unmounting current page
- Refresh timer starts on login/callback and resets on each successful refresh
- All API calls use the latest in-memory access token (updated after refresh)

**Integration tests verifying refresh and expiry flows**

## **Technical Design**

**- Proactive Token Refresh**

Integrated into the auth context from story 4a.

**Mechanism:**
- After login or successful refresh, schedule next refresh based on access token `exp` claim (e.g., refresh at 80% of token lifetime)
- Call `POST /auth/refresh` — refresh token sent via cookie automatically
- On success: update in-memory access token, reschedule next refresh
- On failure (401): stop refresh timer, trigger session expiry modal

**Edge Cases:**
- Tab regains focus after being idle — check token expiry immediately, refresh if needed
- Multiple rapid refresh attempts — deduplicate with a "refreshing" flag
- Network temporarily unavailable — retry once before showing expiry modal

**- Session Expiry Modal**

Non-blocking dialog shown when session expires (FR-020).

**Capabilities:**
- Triggered when token refresh fails (401 response)
- Shows message: "Your session has expired. Please log in again."
- "Log In" button navigates to `/auth/login` (preserving return URL)
- Does NOT auto-redirect — user must take action
- Works independently per browser tab
- Rendered as overlay — does not unmount the current page content

**- Token Transport (Refresh-Specific)**

| Endpoint | Refresh Token | Access Token |
|----------|---------------|--------------|
| POST /auth/refresh | Sent automatically via cookie | Received in JSON response body |

## **Definition of Done**

- Proactive token refresh working before access token expiry
- Session expiry modal (not auto-redirect) shown on refresh failure
- Multi-tab expiry detection working independently
- Refresh timer resets correctly on each successful refresh
- Tab focus triggers expiry check
- All components tested
- Code reviewed and merged

## **Technical Notes**

**Files to Create:**
- `src/components/SessionExpiredModal.tsx` — Session expiry dialog (FR-020)

**Files to Modify:**
- `src/contexts/AuthContext.tsx` — Add refresh scheduling, expiry detection, modal trigger

**Key Considerations:**
- Refresh scheduling should use `setTimeout` based on token `exp` claim, not `setInterval`
- Deduplicate concurrent refresh attempts (e.g., multiple API calls failing simultaneously)
- On tab focus (`visibilitychange` event), check if token is expired and refresh immediately
- Modal must be an overlay that preserves current page state — not a route redirect
- Access token lifetime is 15 minutes (default), so refresh around the 12-minute mark

## **References**

Related Stories:
- AAP-64620: Nexus Authentication and Authorization (Epic)
- Story 4a: Core Authentication Flow (UI) — prerequisite, provides auth context this story extends
- AAP-65190: OAuth2 Login Flow (Backend) — implements `POST /auth/refresh` endpoint
