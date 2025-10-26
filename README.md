# musicapp

A music and video streaming application for local artists and content from Mbarara, built with Flutter. The app uses a local SQLite database to manage user data, media metadata, and favorites, operating entirely offline.

### Features

**Guest Users (Not Logged In):**
- Browse and search for all available music and videos.
- Stream any audio or video content.
- Onboarding screens for a better first-time user experience.

**Authenticated Users (Logged In):**
- All guest features.
- Register local media files (audio/video) with the app.
- View a personal profile page with their uploaded content. (Media is stored locally)
- Add/remove media to a personal favorites list.
- View a list of recently played items.
- Download media files to the device's public "Downloads" folder.

### Tech Stack

- **Frontend:** Flutter
- **Database:** SQLite (using `sqflite` for local storage)
- **State Management:** Provider (for audio player and other states)

### Application Flow

1.  **First Launch**: New users are greeted with an onboarding flow. Returning users are taken directly to the `MainScreen`.
2.  **App Structure**: The app is built around a `MainScreen` with a bottom navigation bar containing three tabs: **Home**, **Favorites**, and **Profile**. A persistent `MiniPlayer` is shown at the bottom when audio is playing.
3.  **Guest Experience**: Guests can access the **Home** tab to browse, search, and play all media. The **Favorites** and **Profile** tabs prompt them to log in.
4.  **User Authentication**: Users can log in or register. Upon successful login, their session is stored locally in the SQLite database.
5.  **Authenticated Experience**: Once logged in, all tabs are fully functional. The **Favorites** tab shows their saved media, and the **Profile** tab displays their registered content and a logout button.

### Installation and Setup

Follow these steps to get the project running locally.

1.  **Prerequisites**: Ensure you have the Flutter SDK installed.
2.  **Clone Repository**: `git clone <your-repository-url>`
3.  **Install Dependencies**: Navigate to the project root and run `flutter pub get`.
4.  **Run the App**: Connect a device or start an emulator and run `flutter run`. The app will create a local SQLite database on first launch.

### Project Structure

```
musicapp/
├── lib/
|   ├── core/                  # Shared widgets, constants, utilities
|   |   ├── constants.dart
|   |   └── utils.dart
|   |
|   ├── data/                  # Data layer: models and services
|   |   ├── models/
|   |   |   ├── user.dart
|   |   |   └── media.dart
|   |   └── services/
|   |       └── api_service.dart   # Handles all HTTP requests
|   |   
|   ├── features/              # Feature-based modules
|   |   ├── auth/
|   |   |   ├── login_screen.dart
|   |   |   └── registration_screen.dart
|   |   |
|   |   ├── favorites/
|   |   |   └── favorites_screen.dart
|   |   |
|   |   ├── home/
|   |   |   └── home_screen.dart
|   |   |   
|   |   ├── player/
|   |   |   └── media_player_screen.dart
|   |   |
|   |   └── profile/
|   |       ├── profile_screen.dart
|   |       └── upload_screen.dart
|   |   
|   └── main_screen.dart       # App shell with bottom navigation
|
├── pubspec.yaml
└── ... (other project files)
```

### Backend API


The backend is a RESTful API built with PHP.

- `POST /api/register.php`: Creates a new user account.
- `POST /api/login.php`: Authenticates a user and returns a JWT.
- `GET /api/media.php`: Fetches all public media for guest users.
- `POST /api/upload.php`: (Authenticated) Uploads a media file and/or cover art.
- `GET /api/mymedia.php`: (Authenticated) Fetches all media uploaded by the current user.
- `GET /api/download.php`: (Authenticated) Allows downloading a media file by its ID.
- `POST /api/toggle_favorite.php`: (Authenticated) Adds or removes a media item from the user's favorites.
- `GET /api/get_favorites.php`: (Authenticated) Fetches all of the user's favorited media.

For help getting started with Flutter development, view the online documentation.
