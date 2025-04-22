// index.js – wersja kompatybilna z firebase-functions v6.x+

// Import modułów Firebase Functions v2 i Admin SDK
const functions = require("firebase-functions");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

// Inicjalizacja Firebase Admin SDK
initializeApp();

// Logger z v6+ (functions.logger)
const logger = functions.logger;

// --- Konfiguracja ---
const REGION = "europe-west10";
const MEMORY = "256MiB";
const TIMEOUT = 60;

// --- Funkcje pomocnicze ---
async function getFilteredFcmTokens(targetRole, logContext) {
  logger.debug(`[${logContext}] Pobieranie tokenów dla roli: ${targetRole || 'wszyscy'}`);
  const tokens = new Set();
  try {
    const usersRef = getFirestore().collection("users");
    const allUsersSnapshot = await usersRef.get();

    allUsersSnapshot.forEach((doc) => {
      const user = doc.data();
      if (
        user &&
        Array.isArray(user.roles) &&
        Array.isArray(user.fcmTokens) &&
        user.fcmTokens.length > 0
      ) {
        if (!targetRole || user.roles.includes(targetRole)) {
          user.fcmTokens.forEach((token) => {
            if (typeof token === "string" && token.length > 0) {
              tokens.add(token);
            }
          });
        }
      }
    });
    logger.info(`[${logContext}] Znaleziono ${tokens.size} unikalnych tokenów.`);
  } catch (error) {
    logger.error(`[${logContext}] Błąd podczas pobierania tokenów użytkowników: ${error.message}`, error);
    throw error;
  }
  return Array.from(tokens);
}

async function sendFcmNotifications(tokens, notification, data = {}, logContext) {
  if (!Array.isArray(tokens) || tokens.length === 0) {
    logger.info(`[${logContext}] Brak tokenów do wysłania.`);
    return { successCount: 0, failureCount: 0, responses: [] };
  }

  logger.info(`[${logContext}] Wysyłanie do ${tokens.length} tokenów.`);

  const messagePayload = {
    tokens: tokens,
    notification: notification,
    data: data,
  };

  try {
    const response = await getMessaging().sendEachForMulticast(messagePayload);
    logger.info(`[${logContext}] FCM: Sukcesy=${response.successCount}, Błędy=${response.failureCount}`);

    if (response.failureCount > 0 && Array.isArray(response.responses)) {
      response.responses.forEach((resp, idx) => {
        if (resp && resp.success === false) {
          const failedToken = tokens[idx] || `unknown_token_${idx}`;
          let errorCode = "UNKNOWN_CODE";
          let errorMessage = "Unknown error";

          if (resp.error && typeof resp.error === 'object') {
            errorCode = resp.error.code || errorCode;
            errorMessage = resp.error.message || errorMessage;
          }

          logger.warn(`[${logContext}] Błąd tokenu ${failedToken}: [${errorCode}] ${errorMessage}`);
        }
      });
    }

    return response;
  } catch (error) {
    logger.error(`[${logContext}] Błąd krytyczny przy FCM: ${error.message}`, error);
    throw error;
  }
}

// --- Funkcje główne ---

exports.sendNotificationOnCreate = onDocumentCreated(
  {
    region: REGION,
    document: "{collection}/{documentId}",
    memory: MEMORY,
    timeoutSeconds: TIMEOUT,
  },
  async (event) => {
    const collection = event.params.collection;
    const documentId = event.params.documentId;
    const logContext = `sendNotificationOnCreate/${collection}/${documentId}`;

    logger.info(`[${logContext}] Funkcja wywołana.`);

    try {
      const handledCollections = ['ogloszenia', 'aktualnosci', 'events'];
      if (!handledCollections.includes(collection)) {
        logger.debug(`[${logContext}] Pomijam kolekcję '${collection}' (nieobsługiwana).`);
        return;
      }

      const data = event.data?.data();
      if (!data) {
        logger.warn(`[${logContext}] Brak danych w dokumencie.`);
        return;
      }

      let title = data.title || "Nowa informacja";
      let body = "Sprawdź szczegóły";
      let targetRole;

      if (collection === 'ogloszenia') {
        title = data.title || "Nowe ogłoszenie";
        body = data.content || body;
        targetRole = data.rolaDocelowa;
      } else if (collection === 'aktualnosci') {
        title = data.title || "Nowe aktualności";
        body = data.content || body;
      } else if (collection === 'events') {
        title = data.title || "Nowe wydarzenie";
        body = data.description || body;
      }

      logger.info(`[${logContext}] Powiadomienie: Tytuł='${title}', Rola='${targetRole || 'wszyscy'}'`);

      const notificationPayload = { title, body };
      const dataPayload = { sourceCollection: collection, sourceDocId: documentId };

      const tokens = await getFilteredFcmTokens(targetRole, logContext);

      if (tokens.length > 0) {
        await sendFcmNotifications(tokens, notificationPayload, dataPayload, logContext);
      } else {
        logger.info(`[${logContext}] Brak tokenów do wysyłki.`);
      }

      logger.info(`[${logContext}] Gotowe.`);
    } catch (error) {
      logger.error(`[${logContext}] Nieobsłużony błąd:`, error);
    }
  }
);

exports.sendManualNotification = onCall(
  {
    region: REGION,
    memory: MEMORY,
    timeoutSeconds: TIMEOUT,
  },
  async (request) => {
    const logContext = "sendManualNotification";

    const { title, body, targetRole } = request.data || {};

    if (!title || typeof title !== 'string' || title.trim() === '') {
      logger.error(`[${logContext}] Nieprawidłowy tytuł.`, request.data);
      throw new HttpsError('invalid-argument', 'Pole "title" jest wymagane.');
    }

    if (!body || typeof body !== 'string' || body.trim() === '') {
      logger.error(`[${logContext}] Nieprawidłowa treść.`, request.data);
      throw new HttpsError('invalid-argument', 'Pole "body" jest wymagane.');
    }

    logger.info(`[${logContext}] Manualne powiadomienie: Tytuł='${title}', Rola='${targetRole || 'wszyscy'}'`);

    try {
      const notificationPayload = { title: title.trim(), body: body.trim() };
      const dataPayload = { triggeredBy: 'manual' };

      const tokens = await getFilteredFcmTokens(targetRole, logContext);

      let response = { successCount: 0, failureCount: 0 };
      if (tokens.length > 0) {
        response = await sendFcmNotifications(tokens, notificationPayload, dataPayload, logContext);
      } else {
        logger.info(`[${logContext}] Brak tokenów dla wskazanej roli.`);
      }

      return {
        success: true,
        message: `Wysłano. Sukcesy=${response.successCount}, Błędy=${response.failureCount}`,
        details: {
          successCount: response.successCount,
          failureCount: response.failureCount,
          targetedTokensCount: tokens.length,
        },
      };
    } catch (error) {
      logger.error(`[${logContext}] Błąd podczas wysyłki: ${error.message || String(error)}`, error);
      throw new HttpsError('internal', 'Błąd serwera podczas wysyłania powiadomienia.');
    }
  }
);
