<?php
require_once 'db_connect.php';

// This endpoint is now public. No authentication required.
// Check for a valid media ID in the request URL (e.g., /api/download.php?id=123)
if (!isset($_GET['id']) || !filter_var($_GET['id'], FILTER_VALIDATE_INT)) {
    header('Content-Type: application/json');
    echo json_encode(['error' => true, 'message' => 'A valid media ID is required.']);
    exit();
}

$mediaId = (int)$_GET['id'];

// Fetch the file path from the database
$stmt = $conn->prepare("SELECT file_path FROM media WHERE id = ?");
$stmt->bind_param("i", $mediaId);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows == 1) {
    $media = $result->fetch_assoc();
    $relativePath = $media['file_path'];

    // The file_path in the DB is relative to the project root (e.g., 'uploads/audio/xyz.mp3').
    // This script is in the 'api' folder, so we navigate up one level to find the file.
    $filePath = '../' . $relativePath;

    // Check if the file actually exists on the server
    if (file_exists($filePath)) {
        // Set headers to force a download dialog in the client
        header('Content-Description: File Transfer');
        header('Content-Type: application/octet-stream'); // A generic byte stream
        header('Content-Disposition: attachment; filename="' . basename($filePath) . '"');
        header('Expires: 0');
        header('Cache-Control: must-revalidate');
        header('Pragma: public');
        header('Content-Length: ' . filesize($filePath));
        
        // Clear output buffer and read the file to the output
        ob_clean();
        flush();
        readfile($filePath);
        exit();
    }
}

// If the file is not found in the DB or on the filesystem, return a 404 error.
header('Content-Type: application/json');
echo json_encode(['error' => true, 'message' => 'File not found.']);
exit();
?>