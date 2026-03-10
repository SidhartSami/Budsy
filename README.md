<a id="readme-top"></a>

[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![License][license-shield]][license-url]

<br />
<div align="center">
  <h3 align="center">Budsy</h3>
  <p align="center">
    A social companion app built around who you actually are.
    <br />
    <strong>Widget Profiles • Real-Time Chat • Friend Matching</strong>
    <br />
    <br />
    <a href="https://github.com/aliyancat/NotesApp_FullStack/issues/new?labels=bug">Report Bug</a>
    ·
    <a href="https://github.com/aliyancat/NotesApp_FullStack/issues/new?labels=enhancement">Request Feature</a>
  </p>
</div>

<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#about-the-project">About The Project</a></li>
    <li><a href="#features">Features</a></li>
    <li><a href="#technical-design">Technical Design</a></li>
    <li><a href="#built-with">Built With</a></li>
    <li><a href="#getting-started">Getting Started</a></li>
    <li><a href="#team">Team</a></li>
    <li><a href="#license">License</a></li>
  </ol>
</details>

---

## About The Project

Budsy is a social companion app that replaces static bios with a widget-based profile system. Instead of filling out a text description, users build their profile from modular components — expressing personality, interests, and mood through composable widgets that others can see and interact with.

On top of that, Budsy includes a full friend matching system, real-time chat, and push notifications — making it a complete social platform rather than just a profile tool.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Features

### Widget-Based Profiles
The core differentiator. Users build their profile by adding, removing, and arranging widgets — modular components that represent different aspects of their personality. Profiles are dynamic rather than static, and update in real time across all viewers via Firestore.

### Friend & Matching System
Users can discover and connect with others through a matching system. Once matched, both users are added to each other's friends list and can initiate chat.

### Real-Time Chat
Messaging is built on Firestore listeners, meaning messages appear instantly without polling. Conversations are persistent and load previous history on open.

### Push Notifications
Firebase Cloud Messaging (FCM) handles all push notifications — new messages, match requests, and friend activity trigger instant alerts even when the app is backgrounded.

### User Onboarding & Auth
Firebase Auth handles secure sign-up and login. New users are walked through a profile setup flow on first launch, including widget selection and basic profile configuration.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Technical Design

### Architecture
Budsy is built on **MVVM (Model-View-ViewModel)** in Flutter. Business logic and data operations are handled in ViewModels, keeping UI widgets stateless and focused purely on rendering.

### Widget Profile System
Each profile is stored as a structured document in Firestore containing an ordered list of widget configurations. When a user edits their profile, the updated widget list is written back to Firestore and all active listeners reflecting that profile update in real time — no refresh required.

### Real-Time Chat
Each conversation is a Firestore subcollection. Messages are written as documents and read via `snapshots()` stream listeners, delivering new messages to the UI the moment they are committed to the database.

### Push Notifications
FCM tokens are stored per user in Firestore on login. When a triggering event occurs (new message, match request), the backend writes to the relevant document and a Cloud Function dispatches the FCM notification to the target token.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Built With

**Frontend:**
- Flutter — cross-platform mobile UI framework
- Dart — primary development language

**Backend & Services:**
- Firebase Auth — user authentication and session management
- Firebase Firestore — real-time NoSQL database for profiles, messages, and matches
- Firebase Cloud Messaging (FCM) — push notification delivery

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Getting Started

### Prerequisites

- Flutter SDK (3.0+)
- Dart SDK
- Android Studio or VS Code with Flutter extension
- Android device or emulator (API Level 21+)

### Installation

1. Clone the repository
   ```sh
   git clone https://github.com/aliyancat/NotesApp_FullStack.git
   ```

2. Install dependencies
   ```sh
   flutter pub get
   ```

3. Firebase Configuration:
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable Authentication, Firestore, and Cloud Messaging
   - Download `google-services.json` and place it in `android/app/`

4. Run the app
   ```sh
   flutter run
   ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Team

| Contributor |
|---|
| [Sidhart Sami](https://github.com/SidhartSami) |
| [Aliyan Munawwar](https://github.com/aliyancat) |
| [Hadi Armughan](https://github.com/HadiArmughan)) |

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## License

Distributed under the MIT License. See `LICENSE` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

[forks-shield]: https://img.shields.io/github/forks/aliyancat/NotesApp_FullStack.svg?style=for-the-badge
[forks-url]: https://github.com/aliyancat/NotesApp_FullStack/network/members
[stars-shield]: https://img.shields.io/github/stars/aliyancat/NotesApp_FullStack.svg?style=for-the-badge
[stars-url]: https://github.com/aliyancat/NotesApp_FullStack/stargazers
[issues-shield]: https://img.shields.io/github/issues/aliyancat/NotesApp_FullStack.svg?style=for-the-badge
[issues-url]: https://github.com/aliyancat/NotesApp_FullStack/issues
[license-shield]: https://img.shields.io/github/license/aliyancat/NotesApp_FullStack.svg?style=for-the-badge
[license-url]: https://github.com/aliyancat/NotesApp_FullStack/blob/main/LICENSE
