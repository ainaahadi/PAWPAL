"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.resendVerificationEmail = exports.blockUnverified = void 0;
const admin = __importStar(require("firebase-admin"));
const identity_1 = require("firebase-functions/v2/identity");
const https_1 = require("firebase-functions/v2/https");
admin.initializeApp();
/** Block users whose email is not verified */
exports.blockUnverified = (0, identity_1.beforeUserSignedIn)((event) => {
    const u = event.data;
    const hasEmail = !!(u === null || u === void 0 ? void 0 : u.email);
    const verified = !!(u === null || u === void 0 ? void 0 : u.emailVerified);
    if (hasEmail && !verified) {
        throw new https_1.HttpsError("permission-denied", "Verify your email before signing in.");
    }
});
/** Callable to resend the verification email */
exports.resendVerificationEmail = (0, https_1.onCall)(async (request) => {
    var _a;
    const uid = (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!uid)
        throw new https_1.HttpsError("unauthenticated", "Sign in first.");
    const rec = await admin.auth().getUser(uid);
    if (!rec.email)
        throw new https_1.HttpsError("failed-precondition", "No email.");
    if (rec.emailVerified)
        return { message: "Already verified." };
    const acs = {
        url: "https://pawpal-de6dd.firebaseapp.com/",
        handleCodeInApp: true,
    };
    const link = await admin.auth().generateEmailVerificationLink(rec.email, acs);
    return { message: "Verification email sent.", link };
});
//# sourceMappingURL=index.js.map