<?php
require_once 'db_connect.php';

header('Content-Type: application/json');

$response = array('error' => true, 'message' => 'An unknown error occurred.');

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // The client sends JSON, so we need to decode the raw POST data
    $data = json_decode(file_get_contents('php://input'), true);

    if (!isset($data['user_id']) || !isset($data['media_id'])) {
        $response['message'] = 'User ID and Media ID are required.';
    } else {
        $userId = (int)$data['user_id'];
        $mediaId = (int)$data['media_id'];

        // Check if the like already exists
        $stmt = $conn->prepare("SELECT id FROM likes WHERE user_id = ? AND media_id = ?");
        $stmt->bind_param("ii", $userId, $mediaId);
        $stmt->execute();
        $stmt->store_result();

        if ($stmt->num_rows > 0) {
            // Like exists, so remove it (unlike)
            $stmt->close();
            $delete_stmt = $conn->prepare("DELETE FROM likes WHERE user_id = ? AND media_id = ?");
            $delete_stmt->bind_param("ii", $userId, $mediaId);
            if ($delete_stmt->execute()) {
                $response['error'] = false;
                $response['message'] = 'Media unliked.';
            } else {
                $response['message'] = 'Failed to unlike media.';
            }
            $delete_stmt->close();
        } else {
            // Like does not exist, so add it (like)
            $stmt->close();
            $insert_stmt = $conn->prepare("INSERT INTO likes (user_id, media_id) VALUES (?, ?)");
            $insert_stmt->bind_param("ii", $userId, $mediaId);
            if ($insert_stmt->execute()) {
                $response['error'] = false;
                $response['message'] = 'Media liked.';
            } else {
                $response['message'] = 'Failed to like media.';
            }
            $insert_stmt->close();
        }
    }
} else {
    $response['message'] = 'Invalid request method.';
}

$conn->close();
echo json_encode($response);
?>