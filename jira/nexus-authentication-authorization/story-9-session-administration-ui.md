## **Description**

Users need a UI to view and manage their active sessions. This allows them to see where they're logged in and revoke sessions from devices they no longer use.

**Current State:**
- No visibility into active sessions
- No way to revoke sessions from UI
- No session management page

**Proposed Solution:**

Implement session management UI:
- **Sessions List** - Display all active sessions with device/location info
- **Revoke Session** - Allow users to end specific sessions
- **Current Session Indicator** - Highlight which session is the current one

## **Acceptance Criteria**

- Sessions page accessible from user profile/settings menu
- List shows all active sessions with: device info, IP address, login time, expires in
- Current session clearly marked (e.g., "This device" badge)
- Each session has "Revoke" button (except current session)
- Confirmation dialog before revoking session
- Success/error feedback after revoke action
- List refreshes after session revocation
- Empty state shown if only current session exists
- Loading state while fetching sessions

## **Technical Design**

**1. Sessions List Component**

Table/list displaying active sessions.

**Columns/Fields:**
- Device (parsed from User-Agent)
- IP Address
- Login Time (relative, e.g., "2 hours ago")
- Expires In (remaining time)
- Status indicator (current session vs other)
- Actions (Revoke button)

**API:** GET /api/v1/sessions returns:
```json
{
  "sessions": [
    {
      "jti": "unique-token-id",
      "device": "Mozilla/5.0...",
      "ip": "192.168.1.100",
      "issued_at": "2026-02-06T10:30:00Z",
      "expires_in": 28800
    }
  ]
}
```

**2. Revoke Session Flow**

User action to end a session.

**Flow:**
1. Click "Revoke" button
2. Show confirmation dialog: "End this session? The device will need to log in again."
3. Call DELETE /api/v1/sessions/{jti}
4. Show success toast
5. Refresh sessions list

**3. Device Info Parser**

Utility to parse User-Agent into friendly device names.

**Examples:**
- "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120" → "Chrome on Windows"
- "Mozilla/5.0 (Macintosh; Intel Mac OS X) Safari/17" → "Safari on macOS"

## **Definition of Done**

- Sessions page implemented and accessible
- Sessions list displaying all required info
- Current session indicator working
- Revoke functionality with confirmation
- Success/error feedback implemented
- Empty and loading states handled
- Device info parsed into friendly names
- All components tested
- Code reviewed and merged

## **Technical Notes**

**Files to Create:**
- `src/pages/Sessions.tsx` - Sessions management page
- `src/components/SessionsList.tsx` - Sessions list component
- `src/components/RevokeSessionDialog.tsx` - Confirmation dialog
- `src/utils/parseUserAgent.ts` - User-Agent parser utility

**Files to Modify:**
- `src/components/UserMenu.tsx` - Add link to Sessions page
- `src/routes.tsx` - Add Sessions route

**Key Considerations:**
- Parse User-Agent on frontend for display (backend stores raw string)
- Consider using a library like ua-parser-js for User-Agent parsing
- Current session should NOT have revoke option (would log user out immediately)
- Refreshing list after revoke confirms action succeeded

## **References**

Related Stories:
- AAP-64620: Nexus Authentication and Authorization (Epic)

Technical References:
- [ua-parser-js](https://www.npmjs.com/package/ua-parser-js)
