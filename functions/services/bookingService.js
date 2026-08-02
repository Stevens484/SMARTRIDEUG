/* eslint-disable require-jsdoc, max-len */

const {db} = require("../utils/firestore");

const pendingStatus = "pending";
const reservationDurationMs = 2 * 60 * 1000;

function requireString(value, field) {
  if (typeof value !== "string" || value.trim() === "") {
    throw new Error(`${field} is required.`);
  }
  return value.trim();
}

function normalizeSeats(seats) {
  if (!Array.isArray(seats) || seats.isEmpty) {
    throw new Error("Select at least one seat.");
  }

  const normalized = seats.map((seat) => requireString(seat, "Seat"));
  if (new Set(normalized).size !== normalized.length) {
    throw new Error("Each seat can only be selected once.");
  }
  return normalized;
}

async function reserveSeats({uid, busId, routeId, busNumber, routeName, seats, farePerSeat}) {
  const normalizedBusId = requireString(busId, "busId");
  const normalizedRouteId = requireString(routeId, "routeId");
  const selectedSeats = normalizeSeats(seats);
  const normalizedFare = Number(farePerSeat);
  if (!Number.isFinite(normalizedFare) || normalizedFare < 0) {
    throw new Error("farePerSeat must be a valid positive amount.");
  }

  const busRef = db.collection("buses").doc(normalizedBusId);
  const bookingRef = db.collection("bookings").doc();
  const reservationRef = db.collection("seatReservations").doc(bookingRef.id);
  const expiresAt = new Date(Date.now() + reservationDurationMs);

  await db.runTransaction(async (transaction) => {
    const bus = await transaction.get(busRef);
    if (!bus.exists) throw new Error("This bus is no longer available.");

    const reservedSeats = Array.isArray(bus.get("reservedSeats")) ?
      bus.get("reservedSeats") : [];
    if (selectedSeats.some((seat) => reservedSeats.includes(seat))) {
      throw new Error("One or more selected seats are no longer available.");
    }

    transaction.update(busRef, {
      reservedSeats: [...reservedSeats, ...selectedSeats],
      availableSeats: Math.max(0, (Number(bus.get("totalSeats")) || 0) -
        reservedSeats.length - selectedSeats.length),
      updatedAt: new Date(),
    });
    transaction.set(bookingRef, {
      bookingId: bookingRef.id,
      passengerId: uid,
      busId: normalizedBusId,
      busNumber: requireString(busNumber, "busNumber"),
      routeId: normalizedRouteId,
      routeName: requireString(routeName, "routeName"),
      seats: selectedSeats,
      farePerSeat: normalizedFare,
      fare: normalizedFare * selectedSeats.length,
      status: pendingStatus,
      expiresAt,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    transaction.set(reservationRef, {
      reservationId: reservationRef.id,
      bookingId: bookingRef.id,
      passengerId: uid,
      busId: normalizedBusId,
      seats: selectedSeats,
      status: "reserved",
      expiresAt,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  });

  return {bookingId: bookingRef.id, expiresAt: expiresAt.toISOString()};
}

async function releaseBooking({bookingId, uid, expired = false}) {
  const bookingRef = db.collection("bookings").doc(bookingId);
  const reservationRef = db.collection("seatReservations").doc(bookingId);

  await db.runTransaction(async (transaction) => {
    const booking = await transaction.get(bookingRef);
    if (!booking.exists) throw new Error("This booking is no longer available.");
    if (uid && booking.get("passengerId") !== uid) {
      throw new Error("You cannot change this booking.");
    }
    if (booking.get("status") !== pendingStatus) {
      throw new Error("This booking can no longer be cancelled.");
    }

    const busRef = db.collection("buses").doc(booking.get("busId"));
    const bus = await transaction.get(busRef);
    if (!bus.exists) throw new Error("The bus for this booking no longer exists.");

    const seats = booking.get("seats") || [];
    const reservedSeats = Array.isArray(bus.get("reservedSeats")) ?
      bus.get("reservedSeats") : [];
    const remainingSeats = reservedSeats.filter((seat) => !seats.includes(seat));
    const status = expired ? "expired" : "cancelled";
    transaction.update(bookingRef, {status, updatedAt: new Date(), cancelledAt: new Date()});
    transaction.update(reservationRef, {status, updatedAt: new Date()});
    transaction.update(busRef, {
      reservedSeats: remainingSeats,
      availableSeats: Math.max(0, (Number(bus.get("totalSeats")) || 0) - remainingSeats.length),
      updatedAt: new Date(),
    });
  });
}

async function confirmBooking({bookingId, uid}) {
  const bookingRef = db.collection("bookings").doc(bookingId);
  const reservationRef = db.collection("seatReservations").doc(bookingId);

  await db.runTransaction(async (transaction) => {
    const booking = await transaction.get(bookingRef);
    if (!booking.exists) throw new Error("This booking is no longer available.");
    if (booking.get("passengerId") !== uid) throw new Error("You cannot confirm this booking.");
    if (booking.get("status") !== pendingStatus) {
      throw new Error("This booking can no longer be confirmed.");
    }
    const expiresAt = booking.get("expiresAt");
    if (expiresAt && expiresAt.toDate() <= new Date()) {
      throw new Error("This reservation has expired.");
    }
    transaction.update(bookingRef, {status: "confirmed", confirmedAt: new Date(), updatedAt: new Date()});
    transaction.update(reservationRef, {status: "confirmed", updatedAt: new Date()});
  });
}

module.exports = {confirmBooking, releaseBooking, reserveSeats};
