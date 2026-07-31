const {onCall} = require("firebase-functions/v2/https");

exports.getDirections = onCall(async (request) => {
  const {origin, destination} = request.data;

  return {
    success: true,
    origin,
    destination,
    message: "Directions function is working.",
  };
});
