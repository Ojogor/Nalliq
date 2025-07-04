# Firebase Configuration Setup

This project uses a secure Firebase configuration system to keep sensitive credentials out of version control.

## Setup Instructions

1. **Copy the template file:**
   ```bash
   cp config/firebase_config.template.json config/firebase_config.json
   ```

2. **Fill in your Firebase credentials:**
   Edit `config/firebase_config.json` and replace all placeholder values with your actual Firebase project credentials:
   
   - `YOUR_WEB_API_KEY` → Your web API key
   - `YOUR_ANDROID_API_KEY` → Your Android API key  
   - `YOUR_IOS_API_KEY` → Your iOS API key
   - `YOUR_PROJECT_ID` → Your Firebase project ID
   - `YOUR_SENDER_ID` → Your messaging sender ID
   - etc.

3. **Never commit the real config file:**
   The `config/firebase_config.json` file is in `.gitignore` to prevent accidentally committing sensitive credentials.

## File Structure

- `config/firebase_config.template.json` - Template file (committed to git)
- `config/firebase_config.json` - Real config file (excluded from git)
- `lib/core/config/secure_firebase_options.dart` - Configuration loader

## Getting Firebase Credentials

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Project Settings (gear icon)
4. Scroll down to "Your apps" section
5. For each platform, you'll find the configuration values

## Security Note

**Never commit your real Firebase configuration to version control!** 
Always use the template system for sharing the project structure while keeping credentials secure.
