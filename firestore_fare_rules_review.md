# Fixed route-fare Firestore rules review

## Fare model

- `fares/{routeId}_{pickupStopId}_{destinationStopId}` stores one fixed fare
  per seat for an administrator-selected, ordered pickup-to-stop pair.
- A route point can be used for boarding or alighting. A passenger's selected
  pickup must have a strictly lower route order than their selected stop.
- Signed-in passengers can read fare records only to quote their selected trip.
- Only authenticated administrators can create, edit, or delete fares.
- On booking creation, a fixed fare must match the stored fare document for
  the selected route, pickup, and destination stop.

## Audit

```json
{
  "score": 5,
  "summary": "Fare records are readable only by authenticated users and writable only by server-authorized administrators. Create and update require the deterministic document ID, bounded labels, a positive integer fare, existing route points, and strictly increasing route order. The rules use post-transaction route points, so a securely validated return route and its fares can be created atomically. Passenger booking creation independently verifies point order and that its fixed fare matches the exact configured route-pair document.",
  "findings": []
}
```
