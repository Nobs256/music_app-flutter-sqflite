<?php
require_once 'db_connect.php';

// Set header to return JSON
header('Content-Type: application/json');

// Response array
$response = array();

// Check if the request method is POST
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // Get the raw POST data from the request body
    $input = json_decode(file_get_contents('php://input'), true);

    // Check if required fields are set and not empty
    if (!empty($input['username']) && !empty($input['email']) && !empty($input['password'])) {
        $username = $input['username'];
        $email = $input['email'];
        $password = $input['password'];

        // Validate email format
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $response['error'] = true;
            $response['message'] = 'Invalid email format.';
        } else {
            // Check if user already exists with the same username or email
            $stmt = $conn->prepare("SELECT id FROM users WHERE username = ? OR email = ?");
            $stmt->bind_param("ss", $username, $email);
            $stmt->execute();
            $stmt->store_result();

            if ($stmt->num_rows > 0) {
                $response['error'] = true;
                $response['message'] = 'User already registered with this email or username.';
                $stmt->close();
            } else {
                // Hash the password for security
                $password_hash = password_hash($password, PASSWORD_DEFAULT);

                // Insert new user into the database
                $stmt = $conn->prepare("INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)");
                $stmt->bind_param("sss", $username, $email, $password_hash);

                if ($stmt->execute()) {
                    $response['error'] = false;
                    $response['message'] = 'User registered successfully.';
                } else {
                    $response['error'] = true;
                    $response['message'] = 'Registration failed. Please try again.';
                }
                $stmt->close();
            }
        }
    } else {
        $response['error'] = true;
        $response['message'] = 'Required fields are missing.';
    }
} else {
    $response['error'] = true;
    $response['message'] = 'Invalid request method.';
}

$conn->close();
echo json_encode($response);
?>