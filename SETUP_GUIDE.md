# GYMatch Setup Guide

This guide will help you set up Google OAuth and email functionality for the GYMatch application.

## Table of Contents
1. [Google OAuth Setup](#google-oauth-setup)
2. [Email Service Setup](#email-service-setup)
3. [Testing](#testing)

---

## Google OAuth Setup

### Step 1: Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Select a project" → "New Project"
3. Enter project name: `GYMatch` → Click "Create"

### Step 2: Enable Google+ API

1. In the sidebar, go to **APIs & Services** → **Library**
2. Search for "Google+ API"
3. Click on it and press **Enable**

### Step 3: Configure OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Select **External** → Click **Create**
3. Fill in the required fields:
   - **App name**: GYMatch
   - **User support email**: Your email
   - **Developer contact email**: Your email
4. Click **Save and Continue**
5. Skip "Scopes" (click **Save and Continue**)
6. Add test users (your email addresses for testing)
7. Click **Save and Continue** → **Back to Dashboard**

### Step 4: Create OAuth 2.0 Credentials

1. Go to **APIs & Services** → **Credentials**
2. Click **+ Create Credentials** → **OAuth client ID**
3. Configure for **Web application**:
   - **Name**: GYMatch Web Client
   - **Authorized JavaScript origins**: 
     - `http://localhost:8080`
     - `http://localhost:5000`
   - **Authorized redirect URIs**:
     - `http://localhost:8080`
     - `http://localhost:5000/api/auth/google/callback`
4. Click **Create**
5. **Copy the Client ID and Client Secret**

### Step 5: Create Android OAuth Client (for mobile)

1. Click **+ Create Credentials** → **OAuth client ID** again
2. Select **Android**
3. Get your SHA-1 fingerprint:
   ```bash
   cd mobile-app/android
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
4. Copy the SHA-1 fingerprint and paste it
5. Package name: `com.example.moovit_app` (from android/app/build.gradle)
6. Click **Create**

### Step 6: Update Backend .env File

Open `backend/.env` and add your credentials:

```env
GOOGLE_CLIENT_ID=YOUR_CLIENT_ID_HERE.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=YOUR_CLIENT_SECRET_HERE
```

---

## Email Service Setup

For password reset functionality, you need to configure email sending.

### Option 1: Gmail (Recommended for Development)

1. **Enable 2-Factor Authentication** on your Gmail account:
   - Go to [Google Account Security](https://myaccount.google.com/security)
   - Enable **2-Step Verification**

2. **Create an App Password**:
   - Go to [App Passwords](https://myaccount.google.com/apppasswords)
   - Select app: **Mail**
   - Select device: **Other** → Enter "GYMatch"
   - Click **Generate**
   - **Copy the 16-character password**

3. **Update backend/.env**:
   ```env
   EMAIL_HOST=smtp.gmail.com
   EMAIL_PORT=587
   EMAIL_USER=your_email@gmail.com
   EMAIL_PASSWORD=your_16_char_app_password
   EMAIL_FROM=GYMatch <noreply@gymatch.com>
   ```

### Option 2: Other Email Providers

#### Outlook/Hotmail
```env
EMAIL_HOST=smtp-mail.outlook.com
EMAIL_PORT=587
EMAIL_USER=your_email@outlook.com
EMAIL_PASSWORD=your_password
```

#### Custom SMTP Server
```env
EMAIL_HOST=smtp.yourdomain.com
EMAIL_PORT=587
EMAIL_USER=your_username
EMAIL_PASSWORD=your_password
```

### Testing Without Email (Development Only)

If you don't want to set up email yet, the app will work in **testing mode**:
- Password reset tokens will be returned in the API response
- Check the backend console logs for the reset token
- Use the token manually in the reset password screen

---

## Testing

### Test Google OAuth

1. **Start the backend**:
   ```bash
   cd backend
   npm run dev
   ```

2. **Start the Flutter app**:
   ```bash
   cd mobile-app
   flutter run -d web-server --web-hostname localhost --web-port 8080
   ```

3. **Test Google Sign-In**:
   - Click "Sign In with Google"
   - Select your Google account
   - Should redirect to the home screen

### Test Password Reset

1. **Without Email Setup**:
   - Go to "Forgot Password"
   - Enter a registered email
   - Check the backend console for the reset token
   - Copy the token and use it in the reset password screen

2. **With Email Setup**:
   - Go to "Forgot Password"
   - Enter a registered email
   - Check your email inbox
   - Click the reset link or copy the token
   - Enter new password

### Test Form Validation

1. **Login Screen**:
   - Type in email field → Button should enable when valid
   - Clear fields → Button should disable
   - Type invalid email → See error message

2. **Register Screen**:
   - Fill all fields → Button enables
   - Passwords don't match → See error message
   - Must check "Terms and Conditions" → Button enables

3. **Forgot Password**:
   - Type email → Button enables
   - Clear email → Button disables

---

## Troubleshooting

### Google OAuth Issues

**Error: "Access blocked: This app's request is invalid"**
- Make sure you added test users in OAuth consent screen
- Verify the client ID matches in .env

**Error: "redirect_uri_mismatch"**
- Check that authorized redirect URIs match exactly
- Include both `http://localhost:8080` and `http://localhost:5000`

### Email Issues

**Error: "Invalid login"**
- For Gmail, make sure you're using an App Password, not your regular password
- Verify 2-Factor Authentication is enabled

**Emails not sending**
- Check backend console for error messages
- Verify EMAIL_USER and EMAIL_PASSWORD are correct
- Try sending a test email from command line

### Form Validation Issues

**Button stays disabled**
- Check browser console for errors
- Make sure you're typing in the fields (not pasting)
- Clear all fields and re-type

---

## Production Deployment

Before deploying to production:

1. **Remove Development Features**:
   - Remove `resetToken` from forgot password response
   - Remove token from email body
   - Set `NODE_ENV=production`

2. **Use Environment Variables**:
   - Never commit `.env` file to git
   - Use secure environment variable management
   - Rotate credentials regularly

3. **Update OAuth URLs**:
   - Add production domain to Google Cloud Console
   - Update authorized origins and redirect URIs
   - Test thoroughly before going live

---

## Support

If you encounter issues:
1. Check backend logs: `npm run dev`
2. Check Flutter logs: `flutter run`
3. Verify all environment variables are set correctly
4. Ensure MySQL is running (XAMPP started)

For more help, check the [Google OAuth Documentation](https://developers.google.com/identity/protocols/oauth2) and [Nodemailer Documentation](https://nodemailer.com/).
