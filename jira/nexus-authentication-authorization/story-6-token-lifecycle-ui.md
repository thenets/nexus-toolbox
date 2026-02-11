## **Description**

The Nexus SPA needs to handle token refresh transparently and provide graceful session recovery when tokens expire, especially in multi-tab scenarios.

**Current State:**
- No automatic token refresh in frontend
- No handling for expired sessions
- No multi-tab session awareness

**Proposed Solution:**

Implement frontend token lifecycle management:
- **Silent Token Refresh** - Automatically refresh tokens before expiry
- **Session Expiry Modal** - Show dialog when session cannot be recovered
- **Multi-Tab Recovery** - Check for valid session before forcing re-login
- **Request Interceptor** - Attach tokens to API requests, handle 401s

## **Acceptance Criteria**

- Access token automatically refreshed before expiry (e.g., at 80% of lifetime = ~12 min)
- Token refresh happens silently without user interruption
- On 401 response, attempt token refresh before failing
- If refresh fails, show session expiry modal (NOT auto-redirect)
- Modal offers "Refresh Page" and "Login Again" options
- Refresh Page checks if another tab logged in (shared HTTP-only cookie)
- If valid session exists after refresh, resume without full re-login
- Request queue holds pending requests during token refresh
- Retry queued requests after successful refresh
- Loading indicator during token refresh attempts
- Session hard limit: 8 hours maximum regardless of activity

## **Technical Design**

**1. Token Refresh Service**

Background service that monitors token expiry.

**Capabilities:**
- Track access token expiration time (from JWT exp claim)
- Trigger refresh at 80% of token lifetime (~12 min for 15-min token)
- Call POST /auth/refresh endpoint
- Update stored access token on success

**2. Session Expiry Modal**

Dialog shown when session cannot be recovered.

**Capabilities:**
- Display "Session Expired" message
- Offer "Refresh Page" button (checks for session from other tab via shared cookie)
- Offer "Login Again" button (redirects to login)
- Prevent background interaction while modal is shown
- Do NOT auto-redirect (prevents limbo state with multiple tabs)
- User can re-authenticate with same AAP session if still valid (seamless, no approval screen)

**3. API Request Interceptor**

Axios/fetch interceptor for token handling.

**Capabilities:**
- Attach Authorization: Bearer header to all API requests
- Intercept 401 responses
- Attempt token refresh on 401
- Retry original request after successful refresh
- Queue concurrent requests during refresh (mutex/lock pattern)
- Trigger session expiry modal if refresh fails

## **Definition of Done**

- Silent token refresh working before expiry
- 401 interceptor triggering refresh attempt
- Session expiry modal implemented (no auto-redirect)
- Multi-tab recovery working (page refresh finds valid session)
- Request queueing during refresh working
- All scenarios tested (refresh success, refresh failure, multi-tab)
- Code reviewed and merged

## **Technical Notes**

**Files to Create:**
- `src/services/tokenRefresh.ts` - Token refresh service
- `src/components/SessionExpiryModal.tsx` - Expiry dialog
- `src/services/apiClient.ts` - Axios instance with interceptors

**Files to Modify:**
- `src/contexts/AuthContext.tsx` - Integrate token refresh service

**Key Considerations:**
- Use mutex/lock to prevent multiple simultaneous refresh attempts
- Queue pending requests while refresh is in progress
- Modal must block interaction but NOT auto-redirect
- Test with multiple browser tabs open
- Access token in memory, refresh token in HTTP-only cookie (JS cannot access)

## **References**

Related Stories:
- AAP-64620: Nexus Authentication and Authorization (Epic)

Technical References:
- [Axios Interceptors](https://axios-http.com/docs/interceptors)
- [Token Refresh Patterns](https://hasura.io/blog/best-practices-of-using-jwt-with-graphql/)
