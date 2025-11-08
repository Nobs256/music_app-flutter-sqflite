<?php
require_once 'db_connect.php';

// Set header to return JSON and allow cross-origin requests
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$response = array();

if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    // Get the current user ID from the token, if available
    // If user_id is passed, we treat the user as logged in.
    $current_user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : null;

    // Construct the base URL for file paths
    $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off' || $_SERVER['SERVER_PORT'] == 443) ? "https://" : "http://";
    $domainName = $_SERVER['HTTP_HOST'];
    $base_url = $protocol . $domainName . rtrim(dirname(dirname($_SERVER['PHP_SELF'])), '/\\') . '/';

    // Prepare the SQL query
    $sql = "
        SELECT 
            m.id, m.title, m.user_id AS artist_id, u.username AS artist, 
            m.file_path, m.cover_art_path, m.media_type, m.upload_date,
            (SELECT COUNT(*) FROM likes WHERE media_id = m.id) AS likes_count
    ";

    if ($current_user_id) {
        // If user is logged in, check their like and subscription status
        $sql .= ",
            (EXISTS(SELECT 1 FROM likes WHERE media_id = m.id AND user_id = ?)) AS has_liked,
            (EXISTS(SELECT 1 FROM subscriptions WHERE artist_id = m.user_id AND subscriber_id = ?)) AS is_subscribed
        ";
    }
    $sql .= " FROM media m JOIN users u ON m.user_id = u.id ORDER BY m.upload_date DESC";

    $stmt = $conn->prepare($sql);

    if ($current_user_id) {
        $stmt->bind_param("ii", $current_user_id, $current_user_id);
    }

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

    // Cast boolean-like values to actual booleans for JSON consistency
    foreach ($media_list as &$media) {
        if (isset($media['has_liked'])) $media['has_liked'] = (bool)$media['has_liked'];
        if (isset($media['is_subscribed'])) $media['is_subscribed'] = (bool)$media['is_subscribed'];
    }

    $response['error'] = false;
    $response['media'] = $media_list;

} else {
    $response['error'] = true;
    $response['message'] = 'Invalid request method.';
}

$conn->close();
echo json_encode($response);
?>