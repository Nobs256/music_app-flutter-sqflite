# Mbarara Grooves

A music and video streaming application for local artists and content from Mbarara, built with Flutter. The app connects to a PHP REST API to provide dynamic content, user authentication, and media management.

### Features

**Guest Users (Not Logged In):**
- Browse and search for all available music and videos.
- Stream any audio or video content.

**Authenticated Users (Logged In):**
- All guest features.
- **Upload Content**: Upload personal audio and video files to the server.
- **Profile Management**: View, edit, and delete their own uploaded content from their profile page.
- Add/remove media to a personal favorites list.
- View a list of recently played items.
- **Offline Access**: Download media for offline playback, accessible from a dedicated "Downloads" tab.

### Tech Stack

- **Frontend:** Flutter
- **Backend:** PHP with a MySQL database (via a REST API)
- **Networking:** `dio` for robust HTTP requests.
- **State Management:** Provider (for audio player and other states)
- **Secure Storage:** `flutter_secure_storage` for securely storing the user's JWT.
- **Local Persistence:** `shared_preferences` for caching recent and downloaded media lists.

### Application Flow

1.  **First Launch**: New users are greeted with an onboarding flow. Returning users are taken directly to the `MainScreen`.
2.  **App Structure**: The app is built around a `MainScreen` with a bottom navigation bar containing three main sections: **Home**, **Favorites**, and **Profile**. A persistent `MiniPlayer` is shown at the bottom when audio is playing.
3.  **Home Screen**: The home screen is the central hub, featuring four tabs:
    - **Recents**: Shows a list of recently played media.
    - **Videos**: Displays all available video content.
    - **Audios**: Displays all available audio content.
    - **Downloads**: Shows media that has been downloaded for offline playback.
4.  **User Authentication**: Users can register and log in via the API. Upon successful login, a JSON Web Token (JWT) is securely stored on the device to manage the session.
5.  **Authenticated Experience**: Once logged in, users can access their **Favorites** and **Profile**. The profile screen allows them to view their uploaded content, upload new files, and manage existing ones (edit/delete).

### Installation and Setup

Follow these steps to get the project running locally.

1.  **Prerequisites**: Ensure you have the Flutter SDK installed.
2.  **Clone Repository**: `git clone <repository-url>`
3.  **Install Dependencies**: Navigate to the project root and run `flutter pub get`.
4.  **Configure API**: In `lib/core/constants.dart`, update the `kApiBaseUrl` to point to your running PHP API instance.
5.  **Run the App**: Connect a device or start an emulator and run `flutter run`.

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
|   |       ├── api_service.dart          # Handles all HTTP requests to the backend
|   |       └── local_storage_service.dart # Manages local data (recents, downloads)
|   |   
|   ├── features/              # Feature-based modules
|   |   ├── auth/
|   |   |   ├── auth_provider.dart
|   |   |   ├── login_screen.dart
|   |   |   └── registration_screen.dart
|   |   |
|   |   ├── home/
|   |   |   └── home_screen.dart
|   |   |   └── favorites_screen.dart
|   |   |
|   |   ├── player/
|   |   |   └── media_player_screen.dart
|   |   |
|   |   └── profile/
|   |       ├── profile_screen.dart
|   |       ├── edit_media_screen.dart
|   |       └── upload_screen.dart
|   |   
|   ├── main.dart
|   └── main_screen.dart       # App shell with bottom navigation & providers
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
- `POST /api/edit_media.php`: (Authenticated) Updates the metadata (e.g., title) of a media item.
- `POST /api/delete_media.php`: (Authenticated) Deletes a media item from the server.

For help getting started with Flutter development, view the online documentation.
