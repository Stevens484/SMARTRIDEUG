# Booking rules review

## Data model used by the transaction

- `buses/{busId}` has `reservedSeats` (confirmed), `pendingSeats` (temporary
  holds), `availableSeats`, and `activeBookingId` (the booking paired with the
  current transaction).
- `bookings/{bookingId}` has immutable ownership and fare details. Its allowed
  lifecycle is `pending_confirmation` → `confirmed`, `cancelled`, or
  `expired`. The two-minute window is represented by `arrivalNotifiedAt` and
  `expiresAt`.
- `routes/{routeId}/stops/{stopId}` has a name, display order, latitude, and
  longitude. Only administrators may change route geometry.

## Red-team assessment

```json
{
  "score": 4,
  "summary": "The proposed rules bind all passenger seat-list changes to an owned booking transition in the same Firestore transaction and keep confirmed seats separate from temporary holds. They do not replace server-side expiration when an app is terminated.",
  "findings": [
    {
      "check": "Update bypass",
      "severity": "minor",
      "issue": "A passenger can open the arrival window for their own pending booking early; Firestore Rules cannot calculate geographical distance from the bus and stop coordinates.",
      "recommendation": "Keep the UI's 100 m gate. For an authoritative anti-tamper gate or expiration while terminated, add a trusted server process (for example FCM/Cloud Run) later."
    },
    {
      "check": "Storage abuse",
      "severity": "minor",
      "issue": "Firestore Rules cannot validate every individual seat value in a list without a fixed seat schema.",
      "recommendation": "Rules cap booking and seat-list sizes; the client transaction rejects duplicates and checks capacity. Use a seats subcollection if arbitrary client seat identifiers become a concern."
    }
  ]
}
```

## Deployment checks

1. Seed existing bus documents with `pendingSeats: []` before enabling the
   rules, or use the administrator bus editor to add that field.
2. Test concurrent holds of the same seat, confirmation, cancellation, and
   expiry in the Firestore emulator before deployment.
3. The Firebase CLI could not be run in this workspace because the local npm
   cache is missing its `async` dependency; validate with `firebase deploy
   --only firestore:rules` in a repaired CLI environment.
