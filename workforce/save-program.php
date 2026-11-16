<?php
/**
 * Save Workforce Program
 * Handles adding new programs and editing existing ones
 */

// Set umask to respect directory ACL defaults (creates files as 666 = rw-rw-rw-)
umask(0000);

// CONFIGURATION: Store data file directly in this directory
$data_file = __DIR__ . '/workforce-programs.json';

header('Content-Type: application/json');

require_once __DIR__ . '/workforce-categories.php';

// Get form data
$id = $_POST['id'] ?? '';
$title = trim($_POST['title'] ?? '');
$url = trim($_POST['url'] ?? '');
$categories = $_POST['categories'] ?? [];
$image = trim($_POST['image'] ?? '');
$description = trim($_POST['description'] ?? '');

// Keep only known industries, in the official order
$categories = is_array($categories) ? array_map('trim', $categories) : [];
$categories = array_values(array_intersect(WORKFORCE_CATEGORIES, $categories));

// Validate required fields
if (empty($title)) {
    echo json_encode(['success' => false, 'message' => 'Program name is required']);
    exit;
}

if (empty($url)) {
    echo json_encode(['success' => false, 'message' => 'Program URL is required']);
    exit;
}

// Validate industries
if (empty($categories)) {
    echo json_encode(['success' => false, 'message' => 'Select at least one industry']);
    exit;
}

// Validate URL format
if (!preg_match('#^(/|https?://www\.ccri\.edu)#', $url)) {
    echo json_encode(['success' => false, 'message' => 'URL must start with / or https://www.ccri.edu']);
    exit;
}

// Validate image path (optional)
if ($image !== '' && !preg_match('#^(/(?!/)|https?://www\.ccri\.edu/)#', $image)) {
    echo json_encode(['success' => false, 'message' => 'Image path must start with / or https://www.ccri.edu']);
    exit;
}

// Load existing programs
$programs = [];
if (file_exists($data_file)) {
    $json_content = file_get_contents($data_file);
    $programs = json_decode($json_content, true) ?: [];
}

// Generate ID if new program
if (empty($id)) {
    // Create URL-safe ID from title
    $id = 'workforce-' . preg_replace('/[^a-z0-9]+/', '-', strtolower($title));
    
    // Make sure ID is unique
    $base_id = $id;
    $counter = 1;
    while (array_search($id, array_column($programs, 'id')) !== false) {
        $id = $base_id . '-' . $counter;
        $counter++;
    }
    
    $is_new = true;
} else {
    $is_new = false;
}

// Create program data
$program = [
    'id' => $id,
    'title' => $title,
    'url' => $url,
    'type' => 'workforce',
    'pathway' => 'Workforce Partnerships',
    'categories' => $categories,
    'category' => $categories[0], // kept for anything still reading the old single field
    'image' => $image,
    'description' => $description
];

// Add or update program
if ($is_new) {
    $programs[] = $program;
    $message = 'Program added successfully';
} else {
    // Find and update existing program
    $found = false;
    foreach ($programs as $index => $existing) {
        if ($existing['id'] === $id) {
            $programs[$index] = $program;
            $found = true;
            break;
        }
    }
    
    if (!$found) {
        echo json_encode(['success' => false, 'message' => 'Program not found']);
        exit;
    }
    
    $message = 'Program updated successfully';
}

// Save to file
$json_content = json_encode($programs, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
if (file_put_contents($data_file, $json_content) === false) {
    // Get more details about the error
    $debug_info = [
        'data_file' => $data_file,
        'dir_exists' => file_exists(__DIR__),
        'dir_writable' => is_writable(__DIR__),
        'file_exists' => file_exists($data_file),
        'file_writable' => file_exists($data_file) ? is_writable($data_file) : 'N/A'
    ];
    
    echo json_encode([
        'success' => false, 
        'message' => 'Failed to save program data',
        'debug' => $debug_info
    ]);
    exit;
}

echo json_encode(['success' => true, 'message' => $message]);
?>
