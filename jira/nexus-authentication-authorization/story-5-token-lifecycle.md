## **Description**

Authenticated sessions need to persist beyond the 15-minute access token lifetime. This requires refresh token rotation with reuse detection, Redis-backed session storage, and graceful multi-tab session recovery.

**Current State:**
- OAuth2 login flow issues tokens (from previous story)
- Tokens expire after 15 minutes with no refresh capability
- No session tracking or revocation support

**Proposed Solution:**

Implement complete token lifecycle management:
- Refresh token storage in Redis with metadata
- Token rotation on refresh (new tokens, old token marked used)
- 30-second grace period for concurrent tab requests
- Reuse detection with emergency revocation
- Multi-tab session recovery via modal dialog

## **Acceptance Criteria**

- POST /auth/refresh accepts refresh token from cookie and returns new token pair
- Refresh tokens stored in Redis with metadata (see schema below)
- Redis TTL matches token expiry (8 hours)
- On refresh: old token marked rotated=true with 30-second grace period, new token issued
- Reuse detection: if rotated token used after grace period, revoke ALL user sessions
- Grace period: rotated token valid for 30 seconds (concurrent tab protection)
- Refresh token cookie updated with new token on each refresh
- Access token returned in response body
- 401 response when refresh token expired or revoked
- Unit tests for rotation, reuse detection, grace period logic
- Integration tests for full refresh flow

## **Technical Design**

**1. Redis Token Storage**

**Key Pattern:** `refresh_token:{jti}`
**TTL:** 8 hours (auto-cleanup)

**Metadata Schema (JSON):**
```json
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "issued_at": "2026-02-06T10:30:00Z",
  "device": "Mozilla/5.0...",
  "ip": "192.168.1.100",
  "rotated": false,
  "rotated_at": null
}
```

**2. Token Rotation Flow**

**Capabilities:**
- Validate incoming refresh token (signature, expiry, Redis existence)
- Check rotated flag and grace period (30 seconds from rotated_at)
- Mark old token as rotated with rotated_at timestamp
- Issue new token pair
- Store new refresh token in Redis

**3. Reuse Detection**

**Capabilities:**
- If token marked rotated AND current_time > rotated_at + 30s: security breach detected
- Revoke ALL refresh tokens for that user (SCAN + DEL by user_id pattern)
- Log `token_revoked` event to auth_events table
- Return 401 with security error

## **Definition of Done**

- Refresh endpoint implemented with token rotation
- Redis integration for token storage and lookup
- Grace period logic (30 seconds) working
- Reuse detection triggering full session revocation
- Automatic Redis cleanup via TTL
- All tests passing
- Code reviewed and merged

## **Technical Notes**

**Files to Create:**
- `src/nexus/core/auth/services/session_service.py` - Redis token operations and rotation logic

**Files to Modify:**
- `src/nexus/api/auth/router.py` - Add /auth/refresh endpoint
- `src/nexus/core/redis.py` - Redis client configuration (if not exists)

**Key Considerations:**
- Use SETEX for atomic set-with-TTL operations
- Use SCAN (not KEYS) for user token lookup to avoid blocking
- Grace period is 30 seconds - protects against race conditions in multi-tab scenarios
- Reuse detection is critical security feature - must revoke ALL user sessions on detection
- Log security events asynchronously to avoid blocking auth operations

## **References**

Related Stories:
- AAP-64620: Nexus Authentication and Authorization (Epic)

Technical References:
- [Token Rotation Best Practices](https://dev.to/jacobsngoodwin/12-store-refresh-tokens-in-redis-1k5d)
- [Redis Session Management](https://medium.com/@senaunalmis/the-secret-of-infinite-sessions-transitioning-to-jwt-redis-and-refresh-token-architecture-3c3bb5517864)
