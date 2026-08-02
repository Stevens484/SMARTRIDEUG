/* eslint-disable require-jsdoc, max-len */

const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {confirmBooking, releaseBooking, reserveSeats} = require("../services/bookingService");
const {db} = require("../utils/firestore");

function withCallableError(error) {
  if (error instanceof HttpsError) throw error;
  throw new HttpsError("failed-precondition", error.message || "Booking request failed.");
}

exports.reserveSeats = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in to reserve a seat.");
  try {
    return await reserveSeats({...request.data, uid: request.auth.uid});
  } catch (error) {
    withCallableError(error);
  }
});

exports.confirmBooking = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in to confirm a booking.");
  try {
    await confirmBooking({bookingId: request.data.bookingId, uid: request.auth.uid});
    return {success: true};
  } catch (error) {
    withCallableError(error);
  }
});

exports.cancelBooking = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in to cancel a booking.");
  try {
    await releaseBooking({bookingId: request.data.bookingId, uid: request.auth.uid});
    return {success: true};
  } catch (error) {
    withCallableError(error);
  }
});

exports.expireReservations = onSchedule("every 1 minutes", async () => {
  const expired = await db.collection("seatReservations")
      .where("status", "==", "reserved")
      .where("expiresAt", "<=", new Date())
      .limit(100)
      .get();
  await Promise.all(expired.docs.map(async (reservation) => {
    try {
      await releaseBooking({bookingId: reservation.get("bookingId"), expired: true});
    } catch (error) {
      if (error.message !== "This booking can no longer be cancelled.") throw error;
    }
  }));
});
