# Google OAuth Setup Guide for GYMatch

## Required Information for Google Cloud Console

### 1. Package Name (Application ID)
```
com.example.moovit_app
```
**Location:** `mobile-app/android/app/build.gradle.kts`

### 2. SHA-1 Certificate Fingerprint (Debug)
```
08:7E:F0:26:C4:FC:A9:63:DB:37:4B:85:74:A5:98:56:C8:B2:71:F3
```

### 3. SHA-256 Certificate Fingerprint (Debug)
```
B9:5E:FE:D8:1E:50:89:EE:6B:32:1F:3F:E2:5A:0D:B6:A7:47:0F:A5:28:CD:5C:A6:0B:64:C5:9E:4B:03:0C:F4
```

---

## Step-by-Step Setup Instructions

### Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing project
3. Name it "GYMatch" or similar

### Step 2: Enable Google Sign-In API

1. Go to **APIs & Services** → **Library**
2. Search for "Google Sign-In API" or "Google+ API"
3. Click **Enable**

### Step 3: Configure OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Select **External** user type
3. Fill in the required information:
   - App name: `GYMatch`
   - User support email: Your email
   - Developer contact: Your email
4. Click **Save and Continue**
5. Skip scopes (click **Save and Continue**)
6. Add test users if needed
7. Click **Save and Continue**

### Step 4: Create OAuth 2.0 Credentials

#### For Android App:

1. Go to **APIs & Services** → **Credentials**
2. Click **+ CREATE CREDENTIALS** → **OAuth client ID**
3. Select **Android** as application type
4. Fill in:
   - **Name:** `GYMatch Android`
   - **Package name:** `com.example.moovit_app`
   - **SHA-1 certificate fingerprint:** `08:7E:F0:26:C4:FC:A9:63:DB:37:4B:85:74:A5:98:56:C8:B2:71:F3`
5. Click **Create**
6. Note: Android credentials don't show a client secret

#### For Web/Backend (if needed):

1. Click **+ CREATE CREDENTIALS** → **OAuth client ID**
2. Select **Web application** as application type
3. Fill in:
   - **Name:** `GYMatch Backend`
   - **Authorized JavaScript origins:**
     - `http://localhost:8080`
     - `http://localhost:5000`
   - **Authorized redirect URIs:**
     - `http://localhost:8080`
     - `http://localhost:5000/api/auth/google/callback`
4. Click **Create**
5. **Copy the Client ID and Client Secret**
6. For Flutter web, put the Web Client ID in `mobile-app/web/index.html`:

```html
<meta name="google-signin-client_id" content="your_actual_client_id.apps.googleusercontent.com">
```

### Step 5: Update Backend .env File

Open `backend/.env` and update:

```env
GOOGLE_CLIENT_ID=your_actual_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your_actual_client_secret
```

### Step 6: Configure Flutter App (if needed)

The Flutter app should automatically use the configured Google Sign-In.

For iOS (future), you'll need to add the reversed client ID to `Info.plist`.

---

## Testing Google OAuth

### 1. Make sure MySQL is running
```bash
# Start MySQL via XAMPP or:
net start MySQL
```

### 2. Start Backend Server
```bash
cd backend
npm run dev
```

### 3. Run Flutter App
```bash
cd mobile-app
flutter run -d web-server --web-hostname localhost --web-port 8080
```

### 4. Test Sign In
- Click "Sign In with Google" on login/register screen
- Select your Google account
- Grant permissions
- Should redirect to app home screen

---

## Troubleshooting

### Error: "API not enabled"
- Go to Google Cloud Console → APIs & Services → Library
- Enable "Google Sign-In API"

### Error: "Invalid client"
- Double-check package name matches exactly: `com.example.moovit_app`
- Verify SHA-1 fingerprint is correct
- Wait 5-10 minutes after creating credentials (propagation time)

### Error: "Access blocked"
- Add your Google account as a test user in OAuth consent screen
- Make sure app is in "Testing" mode

### Get SHA-1 again if needed:
```bash
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

---

## Production Setup (Future)

For production, you'll need to:

1. Create a release keystore:
```bash
keytool -genkey -v -keystore gymatch-release.keystore -alias gymatch -keyalg RSA -keysize 2048 -validity 10000
```

2. Get the release SHA-1:
```bash
keytool -list -v -keystore gymatch-release.keystore -alias gymatch
```

3. Add the release SHA-1 to Google Cloud Console credentials

4. Update `android/app/build.gradle.kts` with signing config

---

## Important Notes

- **Debug keystore** is used for development (localhost testing)
- **Release keystore** is needed for production (Play Store)
- Keep your release keystore and credentials **secure**
- Never commit `.env` files or keystores to git
- The SHA-1 shown here is for your DEBUG keystore only

---

## Quick Reference

| Item | Value |
|------|-------|
| Package Name | `com.example.moovit_app` |
| Debug SHA-1 | `08:7E:F0:26:C4:FC:A9:63:DB:37:4B:85:74:A5:98:56:C8:B2:71:F3` |
| Debug SHA-256 | `B9:5E:FE:D8:1E:50:89:EE:6B:32:1F:3F:E2:5A:0D:B6:A7:47:0F:A5:28:CD:5C:A6:0B:64:C5:9E:4B:03:0C:F4` |
| Debug Keystore Location | `%USERPROFILE%\.android\debug.keystore` |
| Debug Keystore Password | `android` |
| Debug Key Alias | `androiddebugkey` |
| Debug Key Password | `android` |
