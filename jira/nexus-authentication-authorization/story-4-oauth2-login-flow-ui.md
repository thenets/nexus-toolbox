## **Description**

The Nexus SPA needs to handle the OAuth2 authentication flow, including initiating login, processing the callback redirect, and providing logout functionality.

**Current State:**
- No login UI exists
- No OAuth2 redirect handling in the frontend
- No logout functionality

**Proposed Solution:**

Implement the frontend OAuth2 flow:
- **Login Page** - Redirect user to backend /auth/login endpoint
- **Callback Handler** - Process OAuth2 callback, store access token in memory
- **Auth State Management** - Track authentication status across the app
- **Logout** - Clear tokens and trigger front-channel logout via AAP

## **Acceptance Criteria**

- Login page with "Login with AAP" button that initiates OAuth2 flow
- Callback route handles redirect from AAP and stores tokens
- Access token stored in memory only (NOT localStorage/sessionStorage)
- Refresh token handled via HTTP-only cookie (automatic, no JS access)
- Auth context/store provides isAuthenticated, user info, logout function
- Unauthenticated users redirected to login page
- After login, user returned to their original destination
- Logout flow:
  1. Call POST /auth/logout
  2. Clear local auth state
  3. Follow redirect to AAP logout (backend handles this)
  4. User lands back on Nexus login page after AAP logout completes
- Loading states shown during OAuth2 redirect flow
- Error handling for failed authentication (display user-friendly message)
- If AAP unavailable during login: show friendly error message

## **Technical Design**

**1. Login Page**

Simple page with login button that redirects to /auth/login.

**Capabilities:**
- Display "Login with Ansible Automation Platform" button
- Redirect to backend which initiates OAuth2 flow
- Show loading state during redirect
- Display error message if login fails

**2. Callback Handler**

Route that processes the OAuth2 callback.

**Capabilities:**
- Receive tokens from backend response
- Store access token in memory (React state/context)
- Redirect to original destination or dashboard
- Handle error responses gracefully

**3. Auth Context/Store**

Global state management for authentication.

**Capabilities:**
- Provide current user info from token claims (username, email, user_type)
- Expose isAuthenticated boolean
- Provide logout function that calls POST /auth/logout
- Persist auth state across page navigation (memory only)

## **Definition of Done**

- Login page implemented with AAP branding
- Callback handler processing tokens correctly
- Auth context providing user state to entire app
- Logout triggering front-channel logout flow (Nexus → AAP → Nexus login)
- Protected routes redirecting to login
- All components tested
- Code reviewed and merged

## **Technical Notes**

**Files to Create:**
- `src/pages/Login.tsx` - Login page component
- `src/pages/AuthCallback.tsx` - OAuth2 callback handler
- `src/contexts/AuthContext.tsx` - Auth state management
- `src/components/ProtectedRoute.tsx` - Route guard for authenticated routes

**Key Considerations:**
- NEVER store access tokens in localStorage or sessionStorage (XSS risk)
- Access token should only exist in JavaScript memory
- Refresh token is HTTP-only cookie, invisible to JavaScript
- Use React Context or state management library for auth state
- Logout is front-channel: backend redirects to AAP logout, then back to Nexus

## **References**

Related Stories:
- AAP-64620: Nexus Authentication and Authorization (Epic)

Technical References:
- [OWASP Token Storage Best Practices](https://cheatsheetseries.owasp.org/cheatsheets/HTML5_Security_Cheat_Sheet.html#local-storage)
