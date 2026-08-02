# Pickup and stop Firestore rules review

## Data model and access paths

- `stops/{stopId}` is the admin-managed source record.
- `routes/{routeId}/stops/{stopId}` mirrors the same record in route order for
  the passenger picker, map, and fare calculation.
- A route point has `type: pickup | stop`, a name, coordinates, route ID, and
  order. Pickups also require a positive `farePerKilometre`.
- Signed-in passengers read route points and create their own held booking;
  only administrators create, update, or delete route points.

## Rule audit

```json
{
  "score": 4,
  "summary": "The pickup/stop change uses authenticated reads, admin-only writes, matching mirrored IDs, and type/coordinate/rate validation. Booking creation verifies that the selected documents are a pickup and a stop on the selected route and derives the fare rate from the pickup record. The road distance is calculated by the app through OSRM and cannot be independently recomputed in Firestore Rules, so it remains a client-supplied derived value.",
  "findings": [
    {
      "check": "Business logic vs. rules",
      "severity": "minor",
      "issue": "Firestore Rules cannot reproduce an OSRM road-distance calculation, so a modified client can still submit an incorrect positive distance while using genuine pickup and stop IDs.",
      "recommendation": "For payment-grade enforcement, move quote and booking creation to a trusted Cloud Function that calls the routing provider and writes the booking server-side."
    }
  ]
}
```
