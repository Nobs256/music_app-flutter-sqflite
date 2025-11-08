<?php
require_once 'db_connect.php';

header('Content-Type: application/json');

$response = array();

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // 1. Get user ID from POST data
    if (!isset($_POST['user_id']) || (int)$_POST['user_id'] <= 0) {
        $response['error'] = true;
        $response['message'] = 'A valid User ID is required.';
    } else if (isset($_POST['title']) && isset($_FILES['mediaFile'])) {
        $userId = (int)$_POST['user_id'];
        $title = $_POST['title'];

        // --- File Upload Logic ---
        $mediaFile = $_FILES['mediaFile'];
        $coverArtFile = isset($_FILES['coverArtFile']) ? $_FILES['coverArtFile'] : null;

        // Define upload directories (relative to the project root, not the api folder)
        $upload_base_dir = '../uploads/';
        $audio_dir = $upload_base_dir . 'audio/';
        $video_dir = $upload_base_dir . 'video/';
        $cover_art_dir = $upload_base_dir . 'cover_art/';

        // Create directories if they don't exist
        if (!is_dir($audio_dir)) mkdir($audio_dir, 0777, true);
        if (!is_dir($video_dir)) mkdir($video_dir, 0777, true);
        if (!is_dir($cover_art_dir)) mkdir($cover_art_dir, 0777, true);

        // --- Process Media File ---
        $media_file_ext = strtolower(pathinfo($mediaFile['name'], PATHINFO_EXTENSION));
        $media_unique_name = uniqid('media_', true) . '.' . $media_file_ext;
        $media_type = strpos($mediaFile['type'], 'audio') === 0 ? 'audio' : 'video';
        $media_target_path = ($media_type === 'audio' ? $audio_dir : $video_dir) . $media_unique_name;
        $media_db_path = 'uploads/' . ($media_type === 'audio' ? 'audio/' : 'video/') . $media_unique_name;

        // --- Process Cover Art (if provided) ---
        $cover_art_db_path = null;
        if ($coverArtFile && $coverArtFile['error'] == 0) {
            $cover_art_ext = strtolower(pathinfo($coverArtFile['name'], PATHINFO_EXTENSION));
            $cover_art_unique_name = uniqid('cover_', true) . '.' . $cover_art_ext;
            $cover_art_target_path = $cover_art_dir . $cover_art_unique_name;
            $cover_art_db_path = 'uploads/cover_art/' . $cover_art_unique_name;

            // Move cover art file
            if (!move_uploaded_file($coverArtFile['tmp_name'], $cover_art_target_path)) {
                // This is a non-critical error, so we can just report it and continue
                // For a stricter implementation, you could set an error and exit the block.
                error_log("Failed to move cover art for user $userId.");
            }
        }

        // Move media file
        if (move_uploaded_file($mediaFile['tmp_name'], $media_target_path)) {
            // 3. Insert into database
            // Note: The 'artist' column from the original schema is not used here,
            // as we can get the artist's username by joining with the 'users' table.
            $stmt = $conn->prepare("INSERT INTO media (user_id, title, file_path, cover_art_path, media_type) VALUES (?, ?, ?, ?, ?)");
            $stmt->bind_param("issss", $userId, $title, $media_db_path, $cover_art_db_path, $media_type);

            if ($stmt->execute()) {
                $response['error'] = false;
                $response['message'] = 'Media uploaded successfully.';
            } else {
                $response['error'] = true;
                $response['message'] = 'Database insertion failed: ' . $stmt->error;
                // Clean up uploaded files if DB insert fails
                if (file_exists($media_target_path)) unlink($media_target_path);
                if ($cover_art_db_path && file_exists($cover_art_target_path)) unlink($cover_art_target_path);
            }
            $stmt->close();
        } else {
            $response['error'] = true;
            $response['message'] = 'Failed to upload media file.';
        }
    } else {
        $response['error'] = true;
        $response['message'] = 'Required fields (user_id, title, mediaFile) are missing or invalid.';
    }
} else {
    $response['error'] = true;
    $response['message'] = 'Invalid request method.';
}

$conn->close();
echo json_encode($response);
?>