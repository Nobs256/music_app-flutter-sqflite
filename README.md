# musicapp

A music and video streaming application for local artists and content from Mbarara City.

### Features

**Guest Users (Not Logged In):**
- Browse and search for all available music and videos.
- Stream any audio or video content.

**Authenticated Users (Logged In):**
- All guest features.
- Upload their own music and videos.
- View a personal profile page with their uploaded content.
- Download media for offline listening.
- Add/remove media to a personal favorites list.

### Tech Stack

- **Frontend:** Flutter
- **Backend:** PHP
- **Database:** MySQL

### Application Flow

1.  **App Structure**: The app is built around a `MainScreen` with a bottom navigation bar containing three tabs: Home, Favorites, and Profile.
2.  **Guest Experience**: Guests land on the **Home** tab to browse, search, and play public media. The **Favorites** and **Profile** tabs show a message prompting them to log in.
3.  **User Authentication**: Users can navigate to a `LoginScreen` or `RegistrationScreen` from the placeholder tabs. Upon successful login, a JWT is securely stored on the device.
4.  **Authenticated Experience**: Once logged in, all tabs are fully functional. The **Favorites** tab shows their saved media, and the **Profile** tab displays their uploaded content and a logout button. Users can upload new content from the profile page.

### Installation and Setup

Follow these steps to get the project running locally.

#### Part 1: Backend API Setup (on InfinityFree)

1.  **Upload Files**: Sign up for an InfinityFree account. Using an FTP client like FileZilla, upload the entire `backendapi` folder to the `htdocs` directory of your InfinityFree hosting account.
2.  **Create Database**: From the InfinityFree client area, create a new MySQL database. Note the **DB Name**, **DB User**, **DB Host**, and your account **password**.
3.  **Configure Connection**: Navigate to `htdocs/backendapi/api/` and edit the `db_connect.php` file. Replace the placeholder credentials with the ones you noted in the previous step.
4.  **Find API URL**: Your API base URL will be your InfinityFree domain followed by `/backendapi/api`. For example: `http://your-domain.rf.gd/backendapi/api`.

#### Part 2: Frontend App Setup

1.  **Prerequisites**: Ensure you have the Flutter SDK installed.
2.  **Clone Repository**: `git clone <your-repository-url>`
3.  **Install Dependencies**: Navigate to the project root and run `flutter pub get`.
4.  **Configure API URL**: Open `lib/core/constants.dart` and update the `apiBaseUrl` variable with the URL you identified in Part 1, Step 4.
5.  **Run the App**: Connect a device or start an emulator and run `flutter run`.

### Project Structure

The project is organized into a clean, feature-first architecture to promote scalability and maintainability.

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
