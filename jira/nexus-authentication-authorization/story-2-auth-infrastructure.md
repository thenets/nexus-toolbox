CREATED: AAP-64622

## **Description**

Nexus needs a foundational authentication infrastructure before implementing the OAuth2 login flow. This includes JWT token creation/validation services, cryptographic key management, and a modular provider interface to support future OIDC migration.

**Current State:**
- No JWT signing capability exists
- No key management system in place
- No abstraction for swappable auth providers

**Proposed Solution:**

Implement the core authentication infrastructure:
- **Token Service** - Create and validate tokens using ES256 (ECDSA P-256)
- **Key Management** - Load signing keys from mounted secrets (Podman/OpenShift)
- **JWKS Endpoint** - Publish public keys for token verification
- **Provider Interface** - Abstract auth provider to enable OAuth2 now, OIDC later

## **Acceptance Criteria**

- Token service can create access tokens (15-minute expiry) with:
  - **Header**: `alg` ("ES256"), `typ` ("JWT"), `kid` (key ID)
  - **Payload**: `sub` (user ID), `email`, `nexus/username` (format: `<aap-instance-id>/<username>`), `nexus/user_type` (ADMIN|AUDITOR|USER), `nexus/token_type` ("access"), `iss` ("nexus"), `iat`, `exp`
- Token service can create refresh tokens (8-hour expiry) with:
  - **Header**: `alg` ("ES256"), `typ` ("JWT"), `kid` (key ID)
  - **Payload**: `sub` (user ID), `jti` (unique token ID), `nexus/token_type` ("refresh"), `iss` ("nexus"), `iat`, `exp`
- All non-standard JWT claims use `nexus/` namespace prefix to avoid collisions with reserved OIDC claims
- Token service validates tokens with ES256 algorithm enforcement (rejects alg=none)
- Signing keys loaded from file-based secrets at /run/secrets/
- JWKS endpoint (GET /auth/.well-known/jwks.json) returns public keys in JWK format
- AuthProvider protocol defined with get_authorization_url, exchange_code, fetch_user_profile, get_logout_url methods
- OAuth2Provider implementation created (can be tested with mocks)
- Key rotation support: quarterly (90 days) with 30-day grace period for old keys
- Unit tests cover token creation, validation, expiry, and algorithm enforcement

## **Technical Design**

**1. Token Service**

Handles token creation and validation using PyJWT with cryptography support.

**Access Token (15-min expiry):**
```json
{
  "header": {
    "alg": "ES256",
    "typ": "JWT",
    "kid": "2026-01-nexus-primary"
  },
  "payload": {
    "sub": "550e8400-e29b-41d4-a716-446655440000",
    "email": "john.doe@example.com",
    "nexus/username": "aap-prod/john.doe",
    "nexus/user_type": "USER",
    "nexus/token_type": "access",
    "iss": "nexus",
    "iat": 1707216600,
    "exp": 1707217500
  }
}
```

**Refresh Token (8-hour expiry):**
```json
{
  "header": {
    "alg": "ES256",
    "typ": "JWT",
    "kid": "2026-01-nexus-primary"
  },
  "payload": {
    "sub": "550e8400-e29b-41d4-a716-446655440000",
    "jti": "a1b2c3d4-5678-90ab-cdef-1234567890ab",
    "nexus/token_type": "refresh",
    "iss": "nexus",
    "iat": 1707216600,
    "exp": 1707245400
  }
}
```

All non-standard claims use the `nexus/` namespace prefix per [Auth0 namespaced claims guidelines](https://auth0.com/docs/secure/tokens/json-web-tokens/create-custom-claims).
The `nexus/username` uses format `<aap-instance-id>/<username>` to ensure uniqueness across AAP Gateway instances.

**2. Key Management**

Load ECDSA P-256 keys from mounted secret files.

**Capabilities:**
- Read private/public keys from /run/secrets/jwt-private-key and /run/secrets/jwt-public-key
- Read key ID from /run/secrets/jwt-key-id
- Support environment variable fallback for development
- Support key rotation with 30-day grace period (validate against both old and new keys)

**3. AuthProvider Interface**

Protocol class for swappable authentication providers.

**Methods:**
- `get_authorization_url(state, redirect_uri)` - Generate OAuth2/OIDC auth URL
- `exchange_code(code, redirect_uri)` - Exchange auth code for provider tokens
- `fetch_user_profile(access_token)` - Fetch user profile and roles from provider
- `get_logout_url(redirect_uri)` - Generate logout redirect URL

## **Definition of Done**

- Token service implemented with ES256 signing
- Key loading from mounted secrets working
- JWKS endpoint returning valid JWK format
- AuthProvider protocol and OAuth2Provider skeleton created
- All unit tests passing
- Code reviewed and merged

## **Technical Notes**

**Dependencies to Add:**
- `authlib>=1.3.0` - OAuth2 client
- `PyJWT[crypto]>=2.8.0` - JWT with ES256 support

**Files to Create:**
- `src/nexus/core/auth/services/token_service.py` - JWT creation and validation
- `src/nexus/core/auth/providers/base.py` - AuthProvider protocol
- `src/nexus/core/auth/providers/oauth2.py` - OAuth2Provider implementation (skeleton)
- `src/nexus/api/auth/router.py` - Auth routes including JWKS endpoint
- `src/nexus/api/auth/schemas.py` - Request/response models

**Key Considerations:**
- MUST use algorithms=["ES256"] when validating to prevent algorithm confusion attacks
- MUST reject tokens with alg=none
- Keys should be loaded once at startup, not on every request
- JWKS endpoint does not require authentication (public keys only)
- Include kid in JWT header to support key rotation

## **References**

Related Stories:
- AAP-64620: Nexus Authentication and Authorization (Epic)

Technical References:
- [PyJWT ECDSA Documentation](https://pyjwt.readthedocs.io/en/stable/algorithms.html)
- [RFC 7517 - JSON Web Key (JWK)](https://datatracker.ietf.org/doc/html/rfc7517)
