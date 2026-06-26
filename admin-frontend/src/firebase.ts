import { initializeApp } from "firebase/app";
import { getMessaging, getToken, onMessage } from "firebase/messaging";

const firebaseConfig = {
    apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
    authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
    projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
    storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
    messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
    appId: import.meta.env.VITE_FIREBASE_APP_ID,
};

let app = null;
let messaging = null;

// Only initialize if config is present (basic check)
if (firebaseConfig.projectId) {
    try {
        app = initializeApp(firebaseConfig);
        messaging = getMessaging(app);
    } catch (error) {
        console.error("Firebase initialization failed:", error);
    }
} else {
    console.warn("Firebase credentials not found in environment variables. Notifications will be disabled.");
}

export { messaging };

export const requestForToken = async () => {
    if (!messaging) {
        console.error("Firebase messaging is not initialized. Check .env config.");
        throw new Error("Firebase not initialized (Check env keys)");
    }
    try {
        const currentToken = await getToken(messaging, {
            vapidKey: import.meta.env.VITE_FIREBASE_VAPID_KEY,
        });
        if (currentToken) {
            return currentToken;
        } else {
            console.warn("No registration token available. Request permission to generate one.");
            throw new Error("No token received (Permission likely denied)");
        }
    } catch (err: any) {
        console.error("An error occurred while retrieving token: ", err);
        if (err.code === "messaging/permission-blocked" || err.message?.includes("permission")) {
            throw new Error("Notification Permission Denied by Browser. Reset permissions!");
        }
        throw new Error(err.message || "Failed to get FCM Token");
    }
};

export const onMessageListener = () =>
    new Promise((resolve, reject) => {
        if (!messaging) {
            reject("Firebase messaging not initialized");
            return;
        }
        onMessage(messaging, (payload) => {
            resolve(payload);
        });
    });
