<?php
require_once 'db_connect.php';

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

$response = array();

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $data = json_decode(file_get_contents("php://input"));

    if (empty($data->username) || empty($data->password)) {
        $response['error'] = true;
        $response['message'] = 'Username and password are required.';
    } else {
        // Correctly select the 'password_hash' column to match the 'register.php' script
        $stmt = $conn->prepare("SELECT id, username, password_hash FROM users WHERE username = ? LIMIT 1");
        $stmt->bind_param("s", $data->username);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows == 1) {
            $user = $result->fetch_assoc();
            // Verify the password against the stored hash
            if (password_verify($data->password, $user['password_hash'])) {
                $response['error'] = false;
                $response['message'] = 'Login successful.';
                $response['userId'] = $user['id'];
                $response['username'] = $user['username'];
            } else {
                $response['error'] = true;
                $response['message'] = 'Invalid credentials.';
            }
        } else {
            $response['error'] = true;
            $response['message'] = 'Invalid credentials.';
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