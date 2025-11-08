<?php
require_once 'db_connect.php';

// Set header to return JSON
header('Content-Type: application/json');

$response = array();

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
        throw new Exception('Invalid request method.');
    }

    // Get user ID from the GET parameter
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : null;

    if (!$userId || $userId <= 0) {
        throw new Exception('A valid user ID is required.');
    }

    // Construct the base URL for file paths, same as in media.php
    $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off' || $_SERVER['SERVER_PORT'] == 443) ? "https://" : "http://";
    $domainName = $_SERVER['HTTP_HOST'];
    $base_url = $protocol . $domainName . rtrim(dirname(dirname($_SERVER['PHP_SELF'])), '/\\') . '/';

    // 1. Fetch media for the user, including likes count
    $sql_media = "
        SELECT 
            m.id, m.title, m.user_id as artist_id, u.username AS artist, 
            m.file_path, m.cover_art_path, m.media_type, m.upload_date,
            (SELECT COUNT(*) FROM likes WHERE media_id = m.id) AS likes_count
        FROM media m 
        JOIN users u ON m.user_id = u.id
        WHERE m.user_id = ?
        ORDER BY m.upload_date DESC
    ";

    $stmt = $conn->prepare($sql_media);
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $result = $stmt->get_result();

    $media_list = array();
    while ($row = $result->fetch_assoc()) {
        $row['file_path'] = $base_url . $row['file_path'];
        if (!empty($row['cover_art_path'])) {
            $row['cover_art_path'] = $base_url . $row['cover_art_path'];
        }
        $media_list[] = $row;
    }
    $stmt->close();

    // 2. Fetch subscriber count for the user
    $stmt_subs = $conn->prepare("SELECT COUNT(*) as count FROM subscriptions WHERE artist_id = ?");
    $stmt_subs->bind_param("i", $userId);
    $stmt_subs->execute();
    $subscriber_count = $stmt_subs->get_result()->fetch_assoc()['count'] ?? 0;
    $stmt_subs->close();

    $response['error'] = false;
    $response['media'] = $media_list;
    $response['subscriber_count'] = (int)$subscriber_count;

} catch (Exception $e) {
    $response['error'] = true;
    $response['message'] = $e->getMessage();
}

$conn->close();
echo json_encode($response);
?>