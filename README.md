   # 🔐 Login Guide

This application uses a simple email-based login system connected to Google Apps Script. On first login, the system will automatically create a spreadsheet entry for the user.

---

## 🚀 How Login Works

1. User opens the app  
2. Enters email address on login screen  
3. App sends request to Google Apps Script backend  
4. Backend checks if user exists:  
   - If **new user** → creates a new spreadsheet entry  
   - If **existing user** → returns user data  
5. App stores session locally and redirects to dashboard  

---

## 📲 Login Steps (User Guide)

### 1. Open the App
Launch the application on your device/emulator.

### 2. Enter Email
Input your registered email address.  
Example: user@example.com

### 3. Tap Login
Press the **Login** button.

System will:
- Validate email format  
- Call backend API (Google Apps Script)  
- Create user record if first time login  

### 4. Successful Login
If successful:
- Redirected to Dashboard  
- Session saved locally  
- No need to login again unless logged out  

---

## 🧠 First-Time User Behavior

When a new email is used:
- New row is created in Google Spreadsheet  
- Default user data is initialized  
- User marked as active  

---

## ⚠️ Common Issues

### Invalid Email
Use proper format:
example@domain.com

### Login Failed
Possible reasons:
- No internet connection  
- Wrong API URL  
- Google Apps Script not deployed correctly  

### User Not Found (Unexpected)
- Check email spelling/case  
- Verify spreadsheet records exist  

---

## 🔧 Developer Notes

- Backend: Google Apps Script Web App  
- Storage: Google Sheets  
- Authentication: Email-based system (no password)  
- Session: SharedPreferences (Flutter)  

---

## 🔐 Security Note

This is NOT password authentication. It is intended for:
- Internal apps  
- Attendance systems  
- Lightweight user tracking  

For production security, use Firebase Auth or OAuth2.


---

## ⚙️ Setup Guide

### 📌 Prerequisites
Before running the project, ensure you have installed:
- Flutter SDK (stable channel)
- Dart SDK (included with Flutter)
- Git
- GitHub CLI (optional but recommended)
- Android Studio / VS Code
- Google account (for Apps Script + Sheets)

---

### 🧩 Project Setup (Flutter)

1. Clone or create project:
```bash
flutter create attendance_app
cd attendance_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

---

### 🔗 Backend Setup (Google Apps Script)

1. Go to Google Apps Script:
   https://script.google.com

2. Create a new project

3. Paste your backend script (Web App API)

4. Deploy:
   - Click **Deploy > New deployment**
   - Select **Web App**
   - Set access:
     - Execute as: Me
     - Who has access: Anyone

5. Copy the Web App URL and use it in Flutter service:
```dart
const String apiUrl = "YOUR_GOOGLE_APPS_SCRIPT_URL";
```

---

### 📊 Google Sheets Setup

1. Create a Google Spreadsheet
2. Create a sheet named:
   - `users`
3. Ensure columns exist:
   - email
   - name
   - createdAt
   - status

---

## 🚀 Deployment Guide

### 📱 Build APK (Android)

```bash
flutter build apk --release
```

Output location:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

### 🌐 Optional: GitHub Deployment

1. Initialize repo:
```bash
git init
```

2. Create GitHub repo:
```bash
gh repo create attendance_app --public --source=. --remote=origin --push
```

3. Push updates:
```bash
git add .
git commit -m "Initial commit"
git push
```

---

## 🧠 Notes

- Ensure Apps Script is deployed BEFORE running Flutter login
- Update API URL in a secure config (recommended: .env)
- Always test Web App endpoint in browser first
