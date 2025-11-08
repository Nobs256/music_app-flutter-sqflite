<?php
// Database configuration
define('DB_SERVER', 'localhost');
define('DB_USERNAME', 'onlinbvn_nobert'); // <-- IMPORTANT: Replace with your DB username
define('DB_PASSWORD', 'nobs.is.coding');     // <-- IMPORTANT: Replace with your DB password
define('DB_NAME', 'onlinbvn_online');

// Attempt to connect to MySQL database
$conn = new mysqli(DB_SERVER, DB_USERNAME, DB_PASSWORD, DB_NAME);

// Check connection
if($conn->connect_error){
    // Use json response for API calls
    die(json_encode(["error" => true, "message" => "Database connection failed: " . $conn->connect_error]));
}
?>