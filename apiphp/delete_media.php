<?php
require_once 'db_connect.php';

header('Content-Type: application/json');

$response = array();

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (!isset($_POST['media_id']) || !isset($_POST['user_id'])) {
        $response['error'] = true;
        $response['message'] = 'Required fields (media_id, user_id) are missing.';
    } else {
        $mediaId = (int)$_POST['media_id'];
        $userId = (int)$_POST['user_id'];

        // Security Check: First, get file paths and verify ownership.
        $stmt = $conn->prepare("SELECT user_id, file_path, cover_art_path FROM media WHERE id = ?");
        $stmt->bind_param("i", $mediaId);
        $stmt->execute();
        $stmt->store_result();

        if ($stmt->num_rows > 0) {
            $stmt->bind_result($ownerId, $filePath, $coverArtPath);
            $stmt->fetch();

            if ($ownerId == $userId) {
                // User is the owner, proceed with deletion.
                $deleteStmt = $conn->prepare("DELETE FROM media WHERE id = ?");
                $deleteStmt->bind_param("i", $mediaId);

                if ($deleteStmt->execute()) {
                    // Database record deleted, now delete the files from the server.
                    // The paths are relative to the project root, so we add '../'
                    if ($filePath && file_exists('../' . $filePath)) {
                        unlink('../' . $filePath);
                    }
                    if ($coverArtPath && file_exists('../' . $coverArtPath)) {
                        unlink('../' . $coverArtPath);
                    }
                    $response['error'] = false;
                    $response['message'] = 'Media deleted successfully.';
                } else {
                    $response['error'] = true;
                    $response['message'] = 'Database deletion failed: ' . $deleteStmt->error;
                }
                $deleteStmt->close();
            } else {
                $response['error'] = true;
                $response['message'] = 'Authorization error: You do not own this media.';
            }
        } else {
            $response['error'] = true;
            $response['message'] = 'Media not found.';
        }
        $stmt->close();
    }
} else {
    $response['error'] = true;
    $response['message'] = 'Invalid request method.';
}

$conn->close();
echo json_encode($response);
?>