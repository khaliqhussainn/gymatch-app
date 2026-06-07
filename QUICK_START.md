# GYMatch Quick Start Guide

## ✅ What's Been Fixed

1. **Google OAuth Setup** - Environment variables added, credentials documented
2. **Password Reset Email** - Complete email system with fallback mode  
3. **Form Validation** - Reactive buttons that enable/disable as you type

---

## 🚀 Getting Started (Choose Your Path)

### Path A: Quick Testing (No Email, No Google OAuth)

**Best for:** Just want to test the app quickly

1. **Start MySQL/XAMPP**
2. **Start Backend:**
   ```bash
   cd backend
   npm run dev
   ```
3. **Start Flutter App:**
   ```bash
   cd mobile-app
   flutter run -d web-server --web-hostname localhost --web-port 8080
   ```

**What Works:**
- ✅ Email/Password Registration
- ✅ Email/Password Login  
- ✅ Guest Login
- ✅ Form validation (buttons work properly)
- ✅ Password Reset (token shown in console)

**What Doesn't Work:**
- ❌ Google Sign-In (needs credentials)
- ❌ Email sending (token fallback works)

---

### Path B: Full Setup (With Google OAuth)

**Best for:** Complete authentication experience

#### Step 1: Google OAuth Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Create OAuth 2.0 Client:
   - **Type:** Android
   - **Package name:** `com.example.moovit_app`
   - **SHA-1:** `08:7E:F0:26:C4:FC:A9:63:DB:37:4B:85:74:A5:98:56:C8:B2:71:F3`

3. Also create a Web Client (for backend)

4. Update `backend/.env`:
   ```env
   GOOGLE_CLIENT_ID=your_actual_client_id.apps.googleusercontent.com
   GOOGLE_CLIENT_SECRET=your_actual_client_secret
   ```

**Full details:** See `GOOGLE_OAUTH_SETUP.md`

#### Step 2: Start Everything

```bash
# Terminal 1 - Backend
cd backend
npm run dev

# Terminal 2 - Flutter
cd mobile-app
flutter run -d web-server --web-hostname localhost --web-port 8080
```

**What Works:**
- ✅ Everything from Path A
- ✅ Google Sign-In
- ✅ Google Sign-Up

---

### Path C: Production-Ready (With Email Service)

**Best for:** Ready to send real password reset emails

#### Step 1: Setup Gmail App Password

1. Enable 2-Factor Authentication on Gmail
2. Go to: https://myaccount.google.com/apppasswords
3. Generate new app password
4. Copy the 16-character code

#### Step 2: Update .env

```env
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_email@gmail.com
EMAIL_PASSWORD=your_16_char_app_password
EMAIL_FROM=GYMatch <noreply@gymatch.com>
```

#### Step 3: Test Email

```bash
cd backend
npm run dev
```

Try forgot password - you should receive an email!

---

## 🔍 Check Your Configuration

Before starting, run this to see what's configured:

```bash
cd backend
npm run check-config
```

This will show you:
- ✅ What's configured correctly
- ❌ What needs to be set up
- ⚠️  What's optional but recommended

---

## 📱 Testing the Fixes

### Test 1: Form Validation (Fixed!)

1. Open Login screen
2. Start typing email - button should **enable** when both fields filled
3. Delete email - button should **disable** immediately
4. Try Register screen - button enables when all fields + terms checked

**Before:** Buttons stayed disabled randomly
**After:** Buttons respond instantly to your typing ✅

### Test 2: Password Reset Flow

**Without Email (Default):**
```bash
cd backend
npm run dev
```
1. Register test account
2. Go to Forgot Password
3. Enter email
4. Check backend console - token will be logged
5. Copy token to Reset Password screen

**With Email (If configured):**
1. Same as above
2. Check your email inbox instead
3. Click link or copy token from email

### Test 3: Google Sign-In

**If credentials configured:**
1. Click "Sign In with Google"
2. Select Google account
3. Should redirect to home screen
4. Check profile - your Google info should be loaded

---

## 🐛 Troubleshooting

### Problem: Backend won't start

**Check:**
```bash
cd backend
npm run check-config
```

**Common causes:**
- MySQL not running → Start XAMPP
- Wrong DB credentials → Check .env matches your MySQL
- Missing packages → Run `npm install`

### Problem: Google Sign-In fails

**Solutions:**
1. Wait 5-10 minutes after creating credentials
2. Verify Package Name: `com.example.moovit_app`  
3. Verify SHA-1: `08:7E:F0:26:C4:FC:A9:63:DB:37:4B:85:74:A5:98:56:C8:B2:71:F3`
4. Add yourself as test user in OAuth consent screen

### Problem: Submit buttons still disabled

**Solutions:**
1. Make sure you pulled latest code
2. Hot reload Flutter app (press 'r' in terminal)
3. Check all required fields are filled
4. For Register: Terms checkbox must be checked

### Problem: Can't receive password reset emails

**This is OK!** The system falls back to showing the token in:
- API response (visible in network tab)
- Backend console logs

To fix:
- Configure Gmail app password (see Path C above)
- Or use another SMTP service

---

## 📚 Additional Resources

- **FIXES_SUMMARY.md** - Detailed explanation of all fixes
- **GOOGLE_OAUTH_SETUP.md** - Complete OAuth setup guide
- **backend/.env** - Configuration template with comments

---

## ✨ Summary

**3 Issues Fixed:**

1. ✅ **Google OAuth** - Documented setup with your credentials
   - Package: `com.example.moovit_app`
   - SHA-1: `08:7E:F0:26:C4:FC:A9:63:DB:37:4B:85:74:A5:98:56:C8:B2:71:F3`

2. ✅ **Password Reset Email** - Complete system with fallback
   - Professional HTML emails
   - Token fallback if email not configured
   - Works out of the box in development

3. ✅ **Form Button Validation** - Real-time reactive updates
   - Buttons enable/disable as you type
   - Works on Login, Register, and Forgot Password
   - No more stuck disabled buttons!

**Choose your path above and start testing! 🚀**
