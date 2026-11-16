<?php
/**
 * CCRI Program List with Department Integration + Location Data
 * 
 * Fetches program list from catalog XML and enriches with department data.
 * Implements caching for catalog data only (6 hours fresh, 7 days stale).
 * Workforce programs are always read fresh from the local JSON file —
 * no cache needed since it's a local file read and changes on demand.
 */

// Enable error reporting for debugging
// error_reporting(E_ALL);
// ini_set('display_errors', 1);

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

// Load department mappings
require_once __DIR__ . '/department-urls.php';

// Configuration
$CATALOG_URL = 'https://catalog.ccri.edu/programs-study/index.xml';
$CACHE_DIR = __DIR__ . '/cache';
$CACHE_FILE = $CACHE_DIR . '/program-list.json';
$FRESH_CACHE_DURATION = 6 * 3600; // 6 hours
$STALE_CACHE_DURATION = 7 * 24 * 3600; // 7 days

// Workforce programs — always read fresh (local file, no cache needed)
$workforce_programs = [];
$workforce_file = $_SERVER['DOCUMENT_ROOT'] . '/workforce/manage-programs/workforce-programs.json';
$workforce_categories_file = $_SERVER['DOCUMENT_ROOT'] . '/workforce/manage-programs/workforce-categories.php';
if (file_exists($workforce_categories_file)) {
    require_once $workforce_categories_file;
}
if (file_exists($workforce_file)) {
    $workforce_json = file_get_contents($workforce_file);
    $decoded = json_decode($workforce_json, true);
    if (is_array($decoded)) {
        $workforce_programs = $decoded;
    }
}

// Give every workforce program a `categories` list using current industry names.
// `category` (first industry) is kept for anything still reading the old field.
if (function_exists('workforce_program_categories')) {
    foreach ($workforce_programs as $i => $program) {
        $categories = workforce_program_categories($program);
        $workforce_programs[$i]['categories'] = $categories;
        $workforce_programs[$i]['category'] = $categories[0] ?? '';
    }
}

// Create cache directory if needed
if (!is_dir($CACHE_DIR)) {
    mkdir($CACHE_DIR, 0755, true);
}

// Check catalog cache
$use_cache = false;
$cache_age = 0;

if (file_exists($CACHE_FILE)) {
    $cache_age = time() - filemtime($CACHE_FILE);
    if ($cache_age < $FRESH_CACHE_DURATION) {
        $use_cache = true;
    }
}

// Serve fresh catalog cache + fresh workforce programs
if ($use_cache) {
    $cache_minutes = round($cache_age / 60);
    $cache_hours = round($cache_age / 3600, 1);
    header('X-Cache-Status: HIT');
    header('X-Cache-Age-Minutes: ' . $cache_minutes);
    header('X-Cache-Age-Hours: ' . $cache_hours);

    // Merge cached catalog programs with fresh workforce programs
    $catalog_programs = json_decode(file_get_contents($CACHE_FILE), true);
    $output = is_array($catalog_programs) ? array_merge($catalog_programs, $workforce_programs) : $workforce_programs;
    echo json_encode($output, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
    exit;
}

// Fetch fresh catalog data
$catalog_xml = @file_get_contents($CATALOG_URL);

// If fetch failed, try stale cache
if ($catalog_xml === false) {
    if (file_exists($CACHE_FILE) && $cache_age < $STALE_CACHE_DURATION) {
        $cache_hours = round($cache_age / 3600, 1);
        $cache_days = round($cache_age / 86400, 1);
        header('X-Cache-Status: STALE');
        header('X-Cache-Age-Hours: ' . $cache_hours);
        header('X-Cache-Age-Days: ' . $cache_days);
        header('X-Cache-Reason: Catalog-Unavailable');

        $catalog_programs = json_decode(file_get_contents($CACHE_FILE), true);
        $output = is_array($catalog_programs) ? array_merge($catalog_programs, $workforce_programs) : $workforce_programs;
        echo json_encode($output, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
        exit;
    } else {
        // No cache at all — return workforce programs only with an error note
        header('X-Cache-Status: MISS');
        header('X-Cache-Reason: Catalog-Unavailable-No-Cache');
        echo json_encode($workforce_programs, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
        exit;
    }
}

// Parse catalog XML
libxml_use_internal_errors(true);
$xml = simplexml_load_string($catalog_xml);

if ($xml === false) {
    if (file_exists($CACHE_FILE) && $cache_age < $STALE_CACHE_DURATION) {
        $cache_hours = round($cache_age / 3600, 1);
        $cache_days = round($cache_age / 86400, 1);
        header('X-Cache-Status: STALE');
        header('X-Cache-Age-Hours: ' . $cache_hours);
        header('X-Cache-Age-Days: ' . $cache_days);
        header('X-Cache-Reason: XML-Parse-Failed');

        $catalog_programs = json_decode(file_get_contents($CACHE_FILE), true);
        $output = is_array($catalog_programs) ? array_merge($catalog_programs, $workforce_programs) : $workforce_programs;
        echo json_encode($output, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
        exit;
    } else {
        echo json_encode($workforce_programs, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
        exit;
    }
}

// ─── BUILD LOCATION MAP FROM CAMPUS SECTION ───────────────────────────────────
$campus_map = [];
$campus_section = (string) $xml->degreescertificatesbycampustext;

$campus_names = [
    'Flanagan (Lincoln) Campus' => 'Flanagan',
    'Knight (Warwick) Campus' => 'Knight',
    'Liston (Providence) Campus' => 'Liston',
    'Newport County Campus' => 'Newport',
    'Online' => 'Online',
];

foreach ($campus_names as $full_name => $short_name) {
    $pattern = '#<h2[^>]*>(?:<strong>)?' . preg_quote($full_name, '#') . '(?:</strong>)?</h2>(.*?)(?=<h2|$)#s';
    if (preg_match($pattern, $campus_section, $campus_match)) {
        preg_match_all('/<a href="([^"]+)"/', $campus_match[1], $links);
        foreach ($links[1] as $href) {
            if (preg_match('#/programs-study/[^/]+/[^/]+/([^/]+)/#', $href, $m)) {
                $slug = $m[1];
                if (!isset($campus_map[$slug]))
                    $campus_map[$slug] = [];
                if (!in_array($short_name, $campus_map[$slug]))
                    $campus_map[$slug][] = $short_name;
            }
        }
    }
}
// ──────────────────────────────────────────────────────────────────────────────

// Extract catalog programs from A-Z list
$catalog_programs = [];
$text_data = (string) $xml->text;

$dom = new DOMDocument();
@$dom->loadHTML('<?xml encoding="UTF-8">' . $text_data);
$xpath_dom = new DOMXPath($dom);
$links = $xpath_dom->query('//ul/li/a');

foreach ($links as $link) {
    $title = trim($link->textContent);
    $url = $link->getAttribute('href');
    $url_parts = explode('/', trim($url, '/'));
    if (count($url_parts) < 4)
        continue;

    $pathway_slug = $url_parts[1];
    $type_folder = $url_parts[2];
    $program_slug = $url_parts[3];

    $pathway_map = [
        'biology' => 'Environment and Sustainability',
        'business-administration' => 'Business Economics and Data Analytics',
        'chemistry' => 'Science, Technology, Engineering, and Mathematics',
        'communication-film' => 'Communication, Media and Film',
        'community-planning' => 'Education, Government, and Human Services',
        'computer-science-cybersecurity' => 'Computer Science Cybersecurity',
        'computer-studies-information-processing' => 'Science, Technology, Engineering, and Mathematics',
        'criminal-justice' => 'Education, Government, and Human Services',
        'culinary-arts' => 'Culinary Arts',
        'english' => 'Arts and Humanities',
        'fine-arts' => 'Arts and Humanities',
        'general-studies' => 'Arts and Humanities',
        'health-sciences' => 'Health and Health Administration',
        'human-services' => 'Education, Government, and Human Services',
        'liberal-arts' => 'Arts and Humanities',
        'math' => 'Science, Technology, Engineering, and Mathematics',
        'performing-arts' => 'Arts and Humanities',
        'physics-engineering' => 'Science, Technology, Engineering, and Mathematics',
        'professional-studies' => 'Business Economics and Data Analytics',
        'psychology' => 'Education, Government, and Human Services',
        'science' => 'Science, Technology, Engineering, and Mathematics',
        'social-sciences' => 'Education, Government, and Human Services',
        'technical-studies' => 'Science, Technology, Engineering, and Mathematics',
        'world-languages' => 'Arts and Humanities',
    ];

    $pathway = isset($pathway_map[$pathway_slug])
        ? $pathway_map[$pathway_slug]
        : ucwords(str_replace('-', ' ', $pathway_slug));

    $type = 'assoc';
    if ($type_folder === 'dipl')
        $type = 'dipl';
    elseif ($type_folder === 'cert')
        $type = 'cert';
    elseif ($type_folder === 'transfer')
        $type = 'transfer';

    $department = $department_code = '';
    $title_parts = explode(',', $title);
    if (count($title_parts) >= 2) {
        $potential_dept = trim($title_parts[0]);
        $department = isset($DEPARTMENT_NAME_MAP[$potential_dept])
            ? $DEPARTMENT_NAME_MAP[$potential_dept]
            : $potential_dept;
    }

    $locations = isset($campus_map[$program_slug]) ? $campus_map[$program_slug] : [];
    sort($locations);

    $catalog_programs[] = [
        'id' => $program_slug,
        'title' => $title,
        'url' => $url,
        'type' => $type,
        'pathway' => $pathway,
        'department' => $department,
        'department_code' => $department_code,
        'locations' => $locations,
    ];
}

// Cache catalog programs only (not workforce — those are always read fresh)
$catalog_json = json_encode($catalog_programs, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
$write_result = @file_put_contents($CACHE_FILE, $catalog_json);
if ($write_result === false) {
    error_log("program-list.php: Failed to write cache to: " . $CACHE_FILE);
    error_log("program-list.php: Cache dir exists: " . (is_dir($CACHE_DIR) ? 'yes' : 'no'));
    error_log("program-list.php: Cache dir writable: " . (is_writable($CACHE_DIR) ? 'yes' : 'no'));
}

// Merge catalog + fresh workforce and output
$output = array_merge($catalog_programs, $workforce_programs);
header('X-Cache-Status: MISS');
header('X-Cache-Action: Fresh-Fetch');
echo json_encode($output, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
