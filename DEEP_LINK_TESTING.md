# Deep Link Testing Guide

## Package Used: app_links

We use the `app_links` package (version 6.3.2+) instead of the deprecated `uni_links` package. The `app_links` package provides:
- Better Android Gradle Plugin compatibility
- Active maintenance and updates
- Cleaner API with Uri-based handling

## Testing Password Reset Deep Links

### 1. Email Format
The password reset email now includes:
- **Mobile App Deep Link**: `https://gymatch.com/reset-password?token=TOKEN` (opens directly in app)
- **Web Fallback**: `https://app.gymatch.com/reset-password?token=TOKEN` (web browser)
- **Development Scheme**: `gymatch://reset?token=TOKEN` (for testing)

### 2. Testing on Android Emulator/Device

#### Method 1: Using ADB
```bash
# Test HTTPS deep link
adb shell am start -a android.intent.action.VIEW -d "https://gymatch.com/reset-password?token=test123"

# Test app scheme
adb shell am start -a android.intent.action.VIEW -d "gymatch://reset?token=test123"
```

#### Method 2: Using Chrome Browser
1. Open Chrome on Android device/emulator
2. Navigate to: `https://gymatch.com/reset-password?token=test123`
3. Should prompt to open in GYMatch app

### 3. Testing Email Service
To test the email service locally:
1. Update `.env` file with email credentials
2. Run the backend server
3. Use Postman or curl to test forgot password endpoint:
```bash
curl -X POST http://localhost:5000/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'
```

### 4. Back Button Navigation
- **Forgot Password Screen**: Back button now goes directly to Login screen
- **Reset Password Screen**: Back button now goes directly to Login screen
- No more getting stuck in navigation history

### 5. Development Notes
- For local testing, you can use `http://localhost/reset-password?token=TOKEN`
- Android manifest includes both HTTPS and app scheme intent filters
- The app handles deep links through `DeepLinkService` and `app_links` package (modern replacement for uni_links)

### 6. Production Deployment
For production:
1. Register `gymatch.com` domain
2. Set up SSL certificates
3. Configure DNS for deep linking
4. Update `APP_DOMAIN` and `WEB_DOMAIN` in backend `.env`
5. Set up email service with proper SMTP credentials

### 7. Troubleshooting
**Issue**: Deep links open in browser instead of app
**Solution**: 
- Ensure app is installed
- Check Android manifest intent filters
- Verify domain verification is set up

**Issue**: Back button doesn't navigate to login
**Solution**:
- Check that screens use `context.go(AppRoutes.login)` not `context.pop()`