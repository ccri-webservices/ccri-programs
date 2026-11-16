<?php
/**
 * Workforce Categories (Industries)
 * Single source of truth for the workforce industry list.
 * Used by the manager (get/save) and by program-list.php.
 */

// Industries shown in the manager and the directory filters
const WORKFORCE_CATEGORIES = [
    'Advanced Manufacturing',
    'Business and Finance',
    'Construction and Trades',
    'Education',
    'Energy and Utilities',
    'GED & Adult Education',
    'Healthcare and Life Sciences',
    'Hospitality',
    'Maritime Trades',
    'Public Safety',
    'Technology',
    'Transportation and Logistics',
];

// Old category names → new names (November 2026 restructure).
// "Manufacturing and Trades" is split three ways, so it has no automatic
// mapping — those programs keep the old name until edited in the manager.
const WORKFORCE_CATEGORY_RENAMES = [
    'Business and Technology' => 'Business and Finance',
    'Healthcare' => 'Healthcare and Life Sciences',
    'Renewable Energy' => 'Energy and Utilities',
    'Fit2Serve' => 'Public Safety',
    'Transportation Education' => 'Transportation and Logistics',
];

/**
 * Returns a program's categories as a list of current industry names.
 * Handles both the new `categories` array and the old single `category` string.
 */
function workforce_program_categories(array $program): array
{
    if (!empty($program['categories']) && is_array($program['categories'])) {
        $categories = $program['categories'];
    } elseif (!empty($program['category'])) {
        $categories = [$program['category']];
    } else {
        $categories = [];
    }

    $normalized = [];
    foreach ($categories as $category) {
        $category = trim((string) $category);
        $category = WORKFORCE_CATEGORY_RENAMES[$category] ?? $category;
        if ($category !== '' && !in_array($category, $normalized, true)) {
            $normalized[] = $category;
        }
    }
    return $normalized;
}
?>
