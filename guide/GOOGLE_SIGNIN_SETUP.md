# Google Sign-In Setup Instructions

## ✅ Code Implementation: COMPLETE

The following has been implemented:
1. ✅ Added `google_sign_in: ^6.2.1` dependency
2. ✅ Updated `AuthService` with `signInWithGoogle()` method
3. ✅ Added Google Sign-In button to login screen
4. ✅ Updated privacy policy

---

## 🔧 Firebase Console Configuration Required

### Step 1: Enable Google Sign-In Provider

1. Go to [Firebase Console](https://console.firebase.google.com/project/english-app-ece16)
2. Navigate to **Authentication** → **Sign-in method**
3. Click on **Google** provider
4. Click **Enable**
5. Select a support email (your email)
6. Click **Save**

---

### Step 2: Add SHA-1 Fingerprint (Android)

Your keystore SHA-1 fingerprint:
```
48:53:DF:D2:60:91:9E:9D:9A:2B:11:71:87:44:A7:20:5A:6C:1C:62
```

**How to add:**
1. In Firebase Console, go to **Project Settings** (⚙️ gear icon)
2. Scroll down to **Your apps** section
3. Select your Android app (`com.example.gravity_app`)
4. Click **Add fingerprint**
5. Paste the SHA-1 above
6. Click **Save**

---

### Step 3: Download Updated google-services.json

After adding the SHA-1:
1. In Firebase Console → **Project Settings** → **Your apps**
2. Click on your Android app
3. Click **Download google-services.json**
4. Replace the existing file at:
   ```
   android\apps\google-services.json
   ```

---

## 🧪 Testing Google Sign-In

### Test on Real Device (Recommended)
```bash
flutter run --release
```

**Why Release Mode?**
- Google Sign-In requires proper signing
- Debug build won't work without additional debug SHA-1

### Get Debug SHA-1 (Optional, for development testing)
```bash
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```
Then add this SHA-1 to Firebase as well.

---

## ✅ Testing Checklist

- [ ] Firebase Google provider enabled
- [ ] SHA-1 fingerprint added
- [ ] google-services.json downloaded and replaced
- [ ] App tested on real device in release mode
- [ ] Google Sign-In button visible on login screen
- [ ] User can successfully sign in with Google
- [ ] User profile data syncs correctly
- [ ] Sign out works (clears both Firebase and Google session)

---

## 🎨 UI Preview

The login screen now shows:
1. Email/Password fields
2. **Login** button (blue)
3. **"OR"** divider
4. **"Continue with Google"** button (white outline with Google logo)
5. Sign up link

---

## 🐛 Common Issues

### Issue: "ERROR 10" or "Developer Error"
**Cause:** SHA-1 not configured
**Fix:** Add SHA-1 to Firebase Console

### Issue: "Sign-in failed" on real device
**Cause:** google-services.json not updated after SHA-1
**Fix:** Download fresh google-services.json

### Issue: Works on emulator but not device
**Cause:** Different signing keys
**Fix:** Add both debug and release SHA-1

---

## 📊 What Happens When User Signs In with Google

1. Google account picker appears
2. User selects/authorizes account
3. App receives Google credentials
4. Firebase links Google account
5. Firestore user document created/updated with:
   - Email
   - Display name
   - Profile photo URL
   - Provider: "google"
   - Timestamp
6. User role determined (teacher/student)
7. Progress synced from cloud
8. Navigated to dashboard

---

## 🔐 Security Notes

- ✅ No API keys exposed (handled by Firebase SDK)
- ✅ OAuth flow handled securely by Google
- ✅ User data encrypted in transit
- ✅ Sign-out clears all sessions
- ✅ Same security rules apply as email/password

---

**Estimated Setup Time:** 5-10 minutes
**Status:** Ready to configure in Firebase Console

