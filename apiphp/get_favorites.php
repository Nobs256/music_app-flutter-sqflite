<?php
require_once 'db_connect.php';

header('Content-Type: application/json');

$response = array();

if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    try {
        // Get user ID from GET parameter
        $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : null;

        if (!isset($userId) || $userId <= 0) {
            $response['error'] = true;
            $response['message'] = 'A valid User ID is required.';
        }

        $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off' || $_SERVER['SERVER_PORT'] == 443) ? "https://" : "http://";
        $domainName = $_SERVER['HTTP_HOST'];
        $base_url = $protocol . $domainName . rtrim(dirname(dirname($_SERVER['PHP_SELF'])), '/\\') . '/';

        // Join with user_favorites table
        $stmt = $conn->prepare("SELECT m.id, m.title, u.username AS artist, m.file_path, m.cover_art_path, m.media_type, m.upload_date FROM media m JOIN users u ON m.user_id = u.id JOIN user_favorites uf ON m.id = uf.media_id WHERE uf.user_id = ? ORDER BY m.upload_date DESC");
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

        $response['error'] = false;
        $response['media'] = $media_list;
    } catch (Exception $e) {
        $response['error'] = true;
        $response['message'] = $e->getMessage();
    }
} else {
    $response['error'] = true;
    $response['message'] = 'Invalid request method.';
}

$conn->close();
echo json_encode($response);
?>