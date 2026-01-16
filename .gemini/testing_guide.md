# Testing Login/Signup - Manual Instructions

## ✅ All Fixes Applied Successfully

All the login/signup issues have been fixed. Here's what was corrected:

### Fixed Issues

1. ✅ RecaptchaVerifier initialization (using `FirebaseAuthPlatform.instance`)
2. ✅ User document creation after phone authentication
3. ✅ User document creation after Google login
4. ✅ User document creation after Facebook login
5. ✅ Recaptcha container visibility in web/index.html

## How to Test

### Option 1: Run in VS Code

1. Press `F5` or click the "Run and Debug" button
2. Select "Chrome" as the device
3. Wait for the app to compile and launch

### Option 2: Run from Terminal

Open a terminal in the project directory and run:

```bash
flutter run -d chrome
```

### Option 3: Run with Hot Reload

```bash
flutter run -d chrome --web-renderer html
```

## What to Test

### 1. Phone Authentication (OTP)

- [ ] Enter a valid Bangladesh phone number (e.g., 01712345678)
- [ ] Click "OTP পাঠান (Send OTP)"
- [ ] Check if reCAPTCHA appears and verify it
- [ ] Enter the OTP code received
- [ ] Click "যাচাই করুন (Verify)"
- [ ] **Expected**: Should go directly to home screen (NOT signup screen)

### 2. Google Login

- [ ] Click the "Google" button
- [ ] Sign in with your Google account
- [ ] **Expected**: Should go directly to home screen (NOT signup screen)

### 3. Facebook Login

- [ ] Click the "Facebook" button
- [ ] Sign in with your Facebook account
- [ ] **Expected**: Should go directly to home screen (NOT signup screen)

### 4. Existing Users

- [ ] Try logging in with an account that already exists
- [ ] **Expected**: Should go directly to home screen

## Troubleshooting

### If reCAPTCHA doesn't appear

1. Check browser console for errors (F12)
2. Verify `web/index.html` has `<div id="recaptcha-container"></div>`
3. Make sure you're running on web (Chrome)

### If stuck on signup screen

1. Check Firestore to see if user document was created
2. Check browser console for Firestore permission errors
3. Verify Firestore security rules allow user creation

### If social login fails

1. **Google**: Verify Google Client ID in `web/index.html`
2. **Facebook**: Verify Facebook App ID in `web/index.html`
3. Check Firebase Console that providers are enabled

## Expected Behavior

After successful login (any method):

1. User document is automatically created in Firestore with role: `consumer`
2. User is redirected to home screen
3. Signup screen only appears if you manually navigate to it or want to change role

## Browser Console Debugging

Open browser console (F12) and look for:

- ✅ "reCAPTCHA verified" - reCAPTCHA working
- ✅ "OTP: Code sent" - OTP sent successfully
- ✅ "FB SDK Initialized" - Facebook SDK loaded
- ❌ Any Firebase errors - Check Firebase configuration

## Files Modified

- `lib/features/auth/screens/login_screen.dart` - Fixed RecaptchaVerifier and added user document creation
- `web/index.html` - Simplified recaptcha container

## Next Steps

If everything works:

- ✅ Login/signup is complete and working
- Consider adding email/password authentication if needed
- Test on mobile devices (Android/iOS)

If issues persist:

- Share the browser console errors
- Check Firebase Console for authentication logs
- Verify Firestore security rules
