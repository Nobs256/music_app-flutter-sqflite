<?php
require_once 'db_connect.php';

header('Content-Type: application/json');

$response = array();

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (!isset($_POST['media_id']) || !isset($_POST['user_id']) || !isset($_POST['title'])) {
        $response['error'] = true;
        $response['message'] = 'Required fields (media_id, user_id, title) are missing.';
    } else {
        $mediaId = (int)$_POST['media_id'];
        $userId = (int)$_POST['user_id'];
        $newTitle = $_POST['title'];

        // Security Check: Verify the user owns the media before updating.
        $stmt = $conn->prepare("SELECT user_id FROM media WHERE id = ?");
        $stmt->bind_param("i", $mediaId);
        $stmt->execute();
        $stmt->store_result();

        if ($stmt->num_rows > 0) {
            $stmt->bind_result($ownerId);
            $stmt->fetch();

            if ($ownerId == $userId) {
                // User is the owner, proceed with update.
                $updateStmt = $conn->prepare("UPDATE media SET title = ? WHERE id = ?");
                $updateStmt->bind_param("si", $newTitle, $mediaId);
                if ($updateStmt->execute()) {
                    $response['error'] = false;
                    $response['message'] = 'Media updated successfully.';
                } else {
                    $response['error'] = true;
                    $response['message'] = 'Database update failed: ' . $updateStmt->error;
                }
                $updateStmt->close();
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