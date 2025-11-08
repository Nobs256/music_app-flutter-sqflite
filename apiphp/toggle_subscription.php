<?php
require_once 'db_connect.php';

header('Content-Type: application/json');

$response = array('error' => true, 'message' => 'An unknown error occurred.');

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // The client sends JSON, so we need to decode the raw POST data
    $data = json_decode(file_get_contents('php://input'), true);

    if (!isset($data['user_id']) || !isset($data['artist_id'])) {
        $response['message'] = 'Subscriber ID and Artist ID are required.';
    } else {
        $subscriberId = (int)$data['user_id'];
        $artistId = (int)$data['artist_id'];

        // Check if the subscription already exists
        $stmt = $conn->prepare("SELECT id FROM subscriptions WHERE subscriber_id = ? AND artist_id = ?");
        $stmt->bind_param("ii", $subscriberId, $artistId);
        $stmt->execute();
        $stmt->store_result();

        if ($stmt->num_rows > 0) {
            // Subscription exists, so remove it (unsubscribe)
            $stmt->close();
            $delete_stmt = $conn->prepare("DELETE FROM subscriptions WHERE subscriber_id = ? AND artist_id = ?");
            $delete_stmt->bind_param("ii", $subscriberId, $artistId);
            if ($delete_stmt->execute()) {
                $response['error'] = false;
                $response['message'] = 'Unsubscribed successfully.';
            } else {
                $response['message'] = 'Failed to unsubscribe.';
            }
            $delete_stmt->close();
        } else {
            // Subscription does not exist, so add it (subscribe)
            $stmt->close();
            $insert_stmt = $conn->prepare("INSERT INTO subscriptions (subscriber_id, artist_id) VALUES (?, ?)");
            $insert_stmt->bind_param("ii", $subscriberId, $artistId);
            if ($insert_stmt->execute()) {
                $response['error'] = false;
                $response['message'] = 'Subscribed successfully.';
            } else {
                $response['message'] = 'Failed to subscribe.';
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