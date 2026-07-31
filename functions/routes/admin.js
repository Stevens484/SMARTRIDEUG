/* eslint-disable require-jsdoc, max-len */
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {admin, db} = require("../utils/firestore");

const allowedCollections = new Set(["routes", "buses"]);

async function requireAdmin(request) {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in as an administrator.");
  const profile = await db.collection("users").doc(request.auth.uid).get();
  if (profile.get("role") !== "admin") {
    throw new HttpsError("permission-denied", "Administrator access is required.");
  }
}

function cleanData(data) {
  if (!data || typeof data !== "object" || Array.isArray(data)) {
    throw new HttpsError("invalid-argument", "A record object is required.");
  }
  const copy = {...data};
  delete copy.id;
  delete copy.createdAt;
  delete copy.updatedAt;
  return copy;
}

exports.manageTransit = onCall(async (request) => {
  await requireAdmin(request);
  const {action, collection, id, data} = request.data || {};

  if (action === "createDriver") {
    if (!data || !data.name || !data.email || !data.password || data.password.length < 6) {
      throw new HttpsError("invalid-argument", "Name, email, and a six-character password are required.");
    }
    const user = await admin.auth().createUser({email: data.email.trim(), password: data.password, displayName: data.name.trim()});
    await db.collection("users").doc(user.uid).set({name: data.name.trim(), email: data.email.trim(), employeeId: data.employeeId || "", role: "driver", disabled: false, createdAt: admin.firestore.FieldValue.serverTimestamp(), updatedAt: admin.firestore.FieldValue.serverTimestamp()});
    return {success: true, id: user.uid};
  }

  if (action === "updateDriver") {
    if (!id) throw new HttpsError("invalid-argument", "Driver ID is required.");
    const values = cleanData(data);
    delete values.password;
    delete values.role;
    await db.collection("users").doc(id).update({...values, updatedAt: admin.firestore.FieldValue.serverTimestamp()});
    return {success: true};
  }

  if (action === "deleteDriver") {
    if (!id) throw new HttpsError("invalid-argument", "Driver ID is required.");
    const assigned = await db.collection("buses").where("driverId", "==", id).get();
    const batch = db.batch();
    for (const bus of assigned.docs) batch.update(bus.ref, {driverId: admin.firestore.FieldValue.delete(), updatedAt: admin.firestore.FieldValue.serverTimestamp()});
    batch.delete(db.collection("users").doc(id));
    await batch.commit();
    await admin.auth().deleteUser(id);
    return {success: true};
  }

  if (action === "assignDriver") {
    if (!id || !data || !data.driverId) throw new HttpsError("invalid-argument", "Bus and driver are required.");
    await db.runTransaction(async (transaction) => {
      const busRef = db.collection("buses").doc(id);
      const driverRef = db.collection("users").doc(data.driverId);
      const [bus, driver] = await Promise.all([transaction.get(busRef), transaction.get(driverRef)]);
      if (!bus.exists || bus.get("disabled") === true) throw new HttpsError("failed-precondition", "The selected bus is unavailable.");
      if (!driver.exists || driver.get("role") !== "driver" || driver.get("disabled") === true) throw new HttpsError("failed-precondition", "The selected driver is unavailable.");
      const driverBuses = await transaction.get(db.collection("buses").where("driverId", "==", data.driverId));
      for (const assignedBus of driverBuses.docs) {
        if (assignedBus.id !== id) transaction.update(assignedBus.ref, {driverId: admin.firestore.FieldValue.delete(), updatedAt: admin.firestore.FieldValue.serverTimestamp()});
      }
      transaction.update(busRef, {driverId: data.driverId, updatedAt: admin.firestore.FieldValue.serverTimestamp()});
    });
    return {success: true};
  }

  if (action === "disableDriver") {
    if (!id) throw new HttpsError("invalid-argument", "Driver ID is required.");
    const disabled = !data || data.disabled !== false;
    const batch = db.batch();
    batch.set(db.collection("users").doc(id), {disabled, updatedAt: admin.firestore.FieldValue.serverTimestamp()}, {merge: true});
    if (disabled) {
      const assigned = await db.collection("buses").where("driverId", "==", id).get();
      for (const bus of assigned.docs) batch.update(bus.ref, {driverId: admin.firestore.FieldValue.delete(), updatedAt: admin.firestore.FieldValue.serverTimestamp()});
    }
    await batch.commit();
    return {success: true};
  }

  if (action === "createStop" || action === "updateStop" || action === "deleteStop") {
    if (!data || !data.routeId || (action !== "deleteStop" && !data.name)) {
      throw new HttpsError("invalid-argument", "A route and stop name are required.");
    }
    const stopRef = id ? db.collection("routes").doc(data.routeId).collection("stops").doc(id) : db.collection("routes").doc(data.routeId).collection("stops").doc();
    if (action === "createStop") {
      const existingStops = await db.collection("routes").doc(data.routeId).collection("stops").get();
      await stopRef.set({name: data.name.trim(), order: existingStops.size, createdAt: admin.firestore.FieldValue.serverTimestamp(), updatedAt: admin.firestore.FieldValue.serverTimestamp()});
    } else if (action === "updateStop") {
      await stopRef.update({name: data.name.trim(), updatedAt: admin.firestore.FieldValue.serverTimestamp()});
    } else {
      await stopRef.delete();
    }
    return {success: true, id: stopRef.id};
  }

  if (action === "reorderStops") {
    if (!data || !data.routeId || !Array.isArray(data.stopIds)) {
      throw new HttpsError("invalid-argument", "A route and ordered stop IDs are required.");
    }
    const batch = db.batch();
    data.stopIds.forEach((stopId, index) => {
      batch.update(db.collection("routes").doc(data.routeId).collection("stops").doc(stopId), {order: index, updatedAt: admin.firestore.FieldValue.serverTimestamp()});
    });
    await batch.commit();
    return {success: true};
  }

  if (!allowedCollections.has(collection)) throw new HttpsError("invalid-argument", "Unsupported collection.");
  const ref = id ? db.collection(collection).doc(id) : db.collection(collection).doc();
  if (action === "create") {
    const values = cleanData(data);
    await ref.set({...values, disabled: values.disabled === true, createdAt: admin.firestore.FieldValue.serverTimestamp(), updatedAt: admin.firestore.FieldValue.serverTimestamp()});
  } else if (action === "update") {
    const values = cleanData(data);
    await ref.update({...values, updatedAt: admin.firestore.FieldValue.serverTimestamp()});
  } else if (action === "delete") {
    await ref.delete();
  } else if (action === "disable") {
    await ref.update({disabled: !data || data.disabled !== false, updatedAt: admin.firestore.FieldValue.serverTimestamp()});
  } else {
    throw new HttpsError("invalid-argument", "Unsupported action.");
  }
  return {success: true, id: ref.id};
});
