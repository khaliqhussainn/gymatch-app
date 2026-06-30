# Production Server Configuration Required

## CRITICAL: Apple Sign-In Configuration

Before submitting to the App Store again, you **must** update the production server `.env` file.

### SSH into your production server

```bash
ssh user@gymatch.syedmisbahali.com
cd /path/to/backend
```

### Edit the .env file

Add or update this line:

```
APPLE_CLIENT_IDS=com.gymatch.app
```

**Important notes:**
- This must be the **exact** bundle ID from your Xcode project: `com.gymatch.app`
- Do NOT use a Services ID
- Do NOT include multiple bundle IDs (comma-separated)
- Remove any other values that might be there

### Restart the backend

```bash
# If using PM2
pm2 restart gymatch-backend

# Or if using systemd
sudo systemctl restart gymatch-backend

# Or if using node directly
# Kill the process and restart it
```

### Verify the configuration

After restarting, check the server logs when you test Apple Sign-In. You should see:

```
[AuthController.appleLogin] Token aud: com.gymatch.app
[AuthController.appleLogin] Configured audiences: [ 'com.gymatch.app' ]
[AuthController.appleLogin] Success for userId: X
```

If you see an error like `APPLE_CLIENT_IDS is empty`, the configuration is not loaded correctly.

---

## Why this is critical

The investigation found that the most likely cause of the "Connect Now" error is that your production server's `APPLE_CLIENT_IDS` environment variable is either:
- Empty/not set
- Set to the wrong value (e.g., a Services ID instead of the bundle ID)
- Contains multiple incorrect bundle IDs

When Apple reviewers test Sign in with Apple, the token's `aud` field will be `com.gymatch.app`. If this is not in your backend's configured audience list, token verification fails with an audience mismatch error.

---

## Summary of all fixes applied

1. ✅ **Location permission dialog** - Removed "Not Now" button to comply with Apple HIG
2. ✅ **User.js race condition** - Added ER_DUP_ENTRY handling for concurrent Apple login requests
3. ✅ **authController.js logging** - Added comprehensive logging for Apple token verification debugging
4. ✅ **auth_provider.dart error display** - Now shows real server errors instead of generic messages
5. ✅ **sign_in_with_apple package** - Checked (current version 6.1.4 is compatible with dependencies)
6. ⚠️ **Production server .env** - **YOU MUST DO THIS MANUALLY** (instructions above)
