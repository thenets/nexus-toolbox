CREATED: AAP-64620
PARENT: ANSTRAT-1844

## **Background**

**As a** platform user, **I want to** authenticate via AAP Gateway using OAuth 2.0, **so that I can** securely access Nexus with my existing AAP credentials and appropriate role-based permissions.

Nexus requires a secure authentication system that integrates with AAP Gateway as the identity provider. This implementation targets AAP 2.6 capabilities, which supports OAuth 2.0 but not OIDC userinfo claims. The architecture uses a modular provider pattern to allow seamless migration to OIDC when AAP 2.7 is released.

Key architectural decisions:
- **Two-Phase Authentication**: OAuth2 authentication followed by user data retrieval via Gateway REST API
- **No Background Synchronization**: User data synced only during that user's login
- **Stateless JWT**: 15-minute access tokens validated locally without AAP calls
- **Secure Token Storage**: Refresh tokens in HTTP-only cookies, access tokens in memory

## **User Stories**

- As an interactive user, I want to authenticate via AAP Gateway OAuth2 so that I can access Nexus through the web interface.
- As a user, I want my role synchronized from AAP when I log in so that any role changes take effect immediately in Nexus.
- As a user with multiple browser tabs, I want graceful session recovery when my token expires so that I don't lose my work context.

## **Acceptance Criteria**

**Scenario:** Successful OAuth2 Login
- **Given** a user with valid AAP credentials
- **When** they initiate login via Nexus
- **Then** they are redirected to AAP, authenticate, and receive Nexus JWT tokens with their role synced from AAP

**Scenario:** Session Persistence
- **Given** an authenticated user with a valid refresh token
- **When** their access token expires
- **Then** the system transparently refreshes tokens without interrupting their workflow

**Scenario:** Role-Based Access Control
- **Given** users with different roles (USER, AUDITOR, ADMIN)
- **When** they attempt to access protected resources
- **Then** access is granted or denied based on their role permissions

**Scenario:** Security Hardening
- **Given** the complete authentication system
- **When** reviewed against OWASP and OAuth 2.0 best practices
- **Then** all threat mitigations defined in the proposal are implemented and validated
