# Step-by-Step Guide: Migrating from SQLite to PHP API

This document outlines the steps to transition the MusicApp from using a local SQLite database to a dynamic backend powered by the provided PHP REST API.

## Phase 1: Setup and API Service Layer

The first phase is to prepare the app for network communication and build a robust service layer to interact with the API.

### Step 1: Project Setup

1.  **Add HTTP Client:** Add an HTTP client package to `pubspec.yaml` to handle network requests. `dio` is recommended for its features like interceptors and file uploads.
    ```yaml
    dependencies:
      flutter:
        sdk: flutter
      dio: ^5.4.3+1 # Or latest version
      flutter_secure_storage: ^9.2.2 # For securely storing JWT
    ```
2.  **Install Dependencies:** Run `flutter pub get`.
3.  **API Constants:** In `lib/core/constants.dart`, define the base URL for your PHP API.
    ```dart
    const String kApiBaseUrl = 'http://your-domain.com/api'; // Replace with your actual API URL
    ```

### Step 2: Implement the API Service

Refactor or create `lib/data/services/api_service.dart` to handle all network requests.

1.  **Setup Dio:** Configure a `Dio` instance. Use interceptors to automatically add the JWT to authenticated requests.
2.  **Create API Methods:** Implement a method for each API endpoint defined in `README.md`.

    *   `Future<User> register(String username, String password)` -> `POST /register.php`
    *   `Future<String> login(String username, String password)` -> `POST /login.php` (returns JWT)
    *   `Future<List<Media>> getAllMedia()` -> `GET /media.php`
    *   `Future<List<Media>> getMyMedia()` -> `GET /mymedia.php`
    *   `Future<List<Media>> getFavorites()` -> `GET /get_favorites.php`
    *   `Future<void> toggleFavorite(int mediaId)` -> `POST /toggle_favorite.php`
    *   `Future<void> uploadMedia(...)` -> `POST /upload.php` (using `FormData`)
    *   `Future<void> downloadMedia(int mediaId, String savePath)` -> `GET /download.php`

## Phase 2: Authentication Flow

Replace the SQLite-based authentication with API calls and JWT management.

### Step 3: Refactor Authentication Logic

1.  **Create an `AuthProvider`:** Create a new Provider (`lib/features/auth/auth_provider.dart`) to manage the user's authentication state (e.g., JWT, user data, login status).
2.  **Secure Token Storage:** Use `flutter_secure_storage` within `AuthProvider` to save the JWT upon login and retrieve it on app startup.
3.  **Update Login Screen:**
    *   In `login_screen.dart`, call `api_service.login()`.
    *   On success, save the returned JWT using `AuthProvider`.
    *   Navigate to the `MainScreen`.
4.  **Update Registration Screen:**
    *   In `registration_screen.dart`, call `api_service.register()`.
    *   On success, you can either automatically log the user in (by calling the login endpoint) or direct them to the login screen.
5.  **Update Logout:**
    *   The logout function in `profile_screen.dart` should now clear the JWT from secure storage and reset the `AuthProvider` state.

## Phase 3: Feature Migration

Update each feature to fetch data from the API instead of the local database.

### Step 4: Home Screen (All Media)

1.  **Create a `MediaProvider`:** This provider will hold the list of all media.
2.  **Fetch Media:** In `home_screen.dart`, call `api_service.getAllMedia()`.
3.  **Update UI:** Use a `FutureBuilder` or consume the `MediaProvider` to display the list of media fetched from the API.

### Step 5: Favorites Screen

1.  **Create a `FavoritesProvider`:** This provider will manage the user's favorite media.
2.  **Fetch Favorites:** In `favorites_screen.dart`, call `api_service.getFavorites()` to load the user's favorited items.
3.  **Toggle Favorite:** When a user taps the favorite icon on any media item, call `api_service.toggleFavorite(mediaId)`. After the API call succeeds, refresh the favorites list.

### Step 6: Profile Screen (My Media)

1.  **Create a `ProfileProvider`:** This will hold the media uploaded by the logged-in user.
2.  **Fetch User Media:** In `profile_screen.dart`, call `api_service.getMyMedia()` to get the user's content.
3.  **Display Media:** Update the UI to show the fetched list.

### Step 7: Upload and Download

1.  **Update Upload Screen:**
    *   Modify `upload_screen.dart` to use `api_service.uploadMedia()`.
    *   You will need to use `dio`'s `FormData` to package the media file, cover art, and other metadata for the `POST` request.
2.  **Implement Download Logic:**
    *   Create a download button/feature.
    *   When triggered, get the public "Downloads" directory path using a package like `path_provider` and `permission_handler`.
    *   Call `api_service.downloadMedia(mediaId, savePath)` to save the file to the device.

## Phase 4: Cleanup

Once all features are working with the API, you can remove the old database code.

### Step 8: Remove SQLite

1.  **Delete Database Helper:** Remove the `database_helper.dart` file (or equivalent).
2.  **Remove `sqflite`:** Uninstall the `sqflite` and `path` packages from `pubspec.yaml`.
    ```yaml
    # Remove these lines from pubspec.yaml
    sqflite: ...
    path: ...
    ```
3.  **Run `flutter pub get`**.
4.  **Clean Code:** Search the project for any remaining imports or logic related to `sqflite` and delete them. This includes old data models if they are no longer relevant.

By following these steps, you will systematically replace local data handling with dynamic, server-based logic, transforming your application into a fully-fledged client-server app.
