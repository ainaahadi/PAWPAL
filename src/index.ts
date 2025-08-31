import * as admin from "firebase-admin";
import {beforeUserSignedIn} from "firebase-functions/v2/identity";
import {onCall, HttpsError} from "firebase-functions/v2/https";

admin.initializeApp();

/** Block users whose email is not verified */
export const blockUnverified = beforeUserSignedIn((event) => {
  const u = event.data;
  const hasEmail = !!u?.email;
  const verified = !!u?.emailVerified;

  if (hasEmail && !verified) {
    throw new HttpsError(
      "permission-denied",
      "Verify your email before signing in."
    );
  }
});

/** Callable to resend the verification email */
export const resendVerificationEmail = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in first.");

  const rec = await admin.auth().getUser(uid);
  if (!rec.email) throw new HttpsError("failed-precondition", "No email.");
  if (rec.emailVerified) return {message: "Already verified."};

  const acs: admin.auth.ActionCodeSettings = {
    url: "https://pawpal-de6dd.firebaseapp.com/",
    handleCodeInApp: true,
  };

  const link = await admin.auth().generateEmailVerificationLink(rec.email, acs);
  return {message: "Verification email sent.", link};
});
