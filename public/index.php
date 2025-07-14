<?php

// Simple PHP API with OPA integration
header('Content-Type: application/json');

// Get the request method and path
$method = $_SERVER['REQUEST_METHOD'];
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$query = $_GET;

// Simple routing
switch ($path) {
    case '/hello':
        if ($method === 'GET') {
            handleHello($query);
        } else {
            sendError(405, 'Method Not Allowed');
        }
        break;
        
    case '/api/status':
        if ($method === 'GET') {
            handleStatus();
        } else {
            sendError(405, 'Method Not Allowed');
        }
        break;
        
    default:
        sendError(404, 'Not Found');
        break;
}

function handleHello($query) {
    $name = $query['name'] ?? 'World';
    
    $response = [
        'message' => "Hello, {$name}!",
        'timestamp' => date('c'),
        'method' => $_SERVER['REQUEST_METHOD'],
        'path' => parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH)
    ];
    
    echo json_encode($response);
}

function handleStatus() {
    $response = [
        'status' => 'healthy',
        'service' => 'simple-php-opa-api',
        'version' => '1.0.0'
    ];
    
    echo json_encode($response);
}

function sendError($code, $message) {
    http_response_code($code);
    echo json_encode([
        'error' => $message,
        'code' => $code
    ]);
}