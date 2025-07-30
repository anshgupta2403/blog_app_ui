# 📝 Flutter Blog App

A full-stack blog application built with **Flutter**, **Firebase**, and **BLoC** architecture. It allows users to register, create, read, edit, and delete blog posts with a modern, responsive UI and robust backend integration.

---

## 🚀 Features

### ✅ Authentication
- Email + OTP (EmailJS) verification
- Secure login via email/password
- Google Sign-In
- Forgot/Reset password flow

### 📝 Blogging
- Create, edit, and delete blogs
- Tag-based categorization
- Search blogs by title
- Filter your blogs by category,date or sort based on recent|popular

### 📚 Reading & Interaction
- Read blogs with smooth UI
- Like, comment, and share posts
- Follow/unfollow authors
- Notifications for new Posts

### 🔧 Architecture
- Clean Architecture with BLoC pattern
- Firebase Firestore, Auth, and Storage
- Cloud Functions (for notifications, rate limiting, etc.)
- Firestore Emulator support for local development

## 🛠️ Tech Stack

| Tech | Usage |
|------|--------|
| Flutter | Frontend UI |
| Firebase | Auth, Firestore, Storage |
| Firebase Functions | Server-side logic |
| BLoC | State Management |

---

## 🧑‍💻 Getting Started

### Prerequisites
- Flutter 3.x
- Firebase CLI
- Dart 3.x
- Node.js (for Firebase Functions)

### 🔧 Setup

# Clone the repo
git clone https://github.com/anshgupta2403/flutter_blog_app.git
cd blog_app_ui

# Install dependencies
flutter pub get

# Setup Firebase
firebase init
flutterfire configure

# Run app
flutter run
