# CCRI Program Pages System

Automated system for generating and managing CCRI academic program pages, built on CourseLeaf catalog data with a dynamic program directory.

**Last Updated:** July 24, 2026
**Version:** 2.1 (Workforce Cache Fix)

---

## System Overview

```
CourseLeaf Catalog (index.xml)
        │
        ▼
program-list.php ──── department-urls.php
        │                    │
        │              department names
        │
        ├── locations (from degreescertificatesbycampustext)
        ├── pathway mapping
        │
        ├── Cache: program-list.json (catalog only, 6hrs)
        │
        └── workforce-programs.json (always read fresh, never cached)
                │
                ▼
          Merged at response time
                │
                ▼
  program-list.json output (catalog + workforce combined)
        │
        ▼
program-directory.js ──── program-config.js
        │
        ▼
  Directory Page (programs/index.html)
  - Search, pathway, type, location, A-Z filters
  - 24 per page with letter dividers
  - URL state preserved
```

---

## Files

### Server PHP (`/_resources-2025/php/`)

| File                        | Purpose                                                                                                             |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `program-list.php`          | Fetches catalog XML, extracts locations, caches catalog data only, merges workforce programs fresh at response time |
| `fetch-program-content.php` | Fetches & caches individual program content for static pages                                                        |
| `department-urls.php`       | Department name normalization map                                                                                   |

### JavaScript (`/_resources-2025/js/`)

| File                   | Purpose                                                        |
| ---------------------- | -------------------------------------------------------------- |
| `program-config.js`    | Pathway/type maps, hidden programs, pathway order — load first |
| `program-directory.js` | Directory filtering, pagination, chips, URL state              |

### Generation Scripts (run locally)

| File                           | Purpose                                                |
| ------------------------------ | ------------------------------------------------------ |
| `generate-all-programs.php`    | Bulk generate all 98 program pages                     |
| `generate-program-dynamic.php` | Generate a single program page                         |
| `monitor-programs.php`         | Compare catalog to baseline, find new/removed programs |

### Workforce Management (`/workforce/manage-programs/`)

| File                      | Purpose                                                     |
| ------------------------- | ----------------------------------------------------------- |
| `index.html`              | SSO-protected web interface for managing workforce programs |
| `save-program.php`        | Add/edit workforce programs                                 |
| `get-programs.php`        | Retrieve workforce program list                             |
| `delete-program.php`      | Delete workforce programs                                   |
| `workforce-programs.json` | Workforce program data (auto-generated, never cached)       |

---

## Directory Filters

The program directory (`/programs/index.html`) supports:

- **Search** — full-text across program title
- **Pathway** — 7 academic pathways + workforce
- **Type** — Associate, Certificate, Transfer, Diploma, Workforce
- **Location** — Flanagan (Lincoln), Knight (Warwick), Liston (Providence), Newport County, Online
- **Workforce Category** — 8 workforce categories
- **A–Z** — first letter of program title

Active filters show as removable chips. Filter state is preserved in the URL and restored on page load.

---

## Caching Architecture

This is the most important thing to understand about how the system works:

| Data Source               | Cached?                           | Why                                                    |
| ------------------------- | --------------------------------- | ------------------------------------------------------ |
| CourseLeaf catalog XML    | ✅ Yes — 6hrs fresh, 7 days stale | External API call, slow to fetch                       |
| `workforce-programs.json` | ❌ No — always read fresh         | Local file read, takes microseconds, changes on demand |

**The cache file (`program-list.json`) contains catalog programs only.** Workforce programs are merged in at response time every request. This means:

- Workforce changes (add/edit/delete via the manage interface) show up instantly with no cache clearing needed
- Catalog changes take up to 6 hours to appear, or clear the cache to force immediate refresh
- The two data sources can never get out of sync with each other

### To bust the catalog cache

Delete `/_resources-2025/php/cache/program-list.json` via FTP/SFTP. The next page load will fetch fresh from CourseLeaf and write a new cache file.

Cache status is returned in HTTP response headers:

- `X-Cache-Status: HIT` — catalog served from cache, workforce read fresh
- `X-Cache-Status: MISS` — catalog freshly fetched and cached
- `X-Cache-Status: STALE` — catalog unavailable, serving stale cache

---

## Configuration

All JavaScript configuration lives in `program-config.js`. Edit once, affects both the directory page and individual program pages.

### Adding a New Pathway Mapping

```javascript
const PATHWAY_MAP = {
  "New Catalog Pathway Name": "Display Name in UI",
};
```

Also add the PHP-side slug mapping in `program-list.php`:

```php
$pathway_map = [
  'new-pathway-slug' => 'New Catalog Pathway Name',
];
```

### Hiding a Program

```javascript
const HIDDEN_PROGRAMS = [
  "/programs-study/old-program/assoc/discontinued-program/",
];
```

### Reordering the Pathway Filter

```javascript
const PATHWAY_ORDER = [
  "Arts & Humanities",
  "Business, Economics & Data Analytics",
  // ...
];
```

---

## Location Data

Location data comes from the `<degreescertificatesbycampustext>` field in the catalog's `index.xml`. This is a single global field listing all programs by campus — the PHP parses it once and builds a slug → campuses lookup map applied to every program.

The Flanagan campus heading uses a `<strong>` tag wrapper that other campuses don't — this is handled in the regex pattern.

Locations are stored as a comma-separated `data-locations` attribute on each program card (e.g. `"Flanagan,Knight,Online"`). No location badges are shown on cards — the data is used for filtering only.

---

## Catalog API

| Endpoint           | URL                                                                         |
| ------------------ | --------------------------------------------------------------------------- |
| Program list XML   | `https://catalog.ccri.edu/programs-study/index.xml`                         |
| Individual program | `https://catalog.ccri.edu/programs-study/{dept}/{type}/{slug}/`             |
| Content API        | `https://catalog.ccri.edu/ribbit/?page=fose.rjs&route=programs&slug={slug}` |

---

## Deployment Checklist

### New Academic Program Added to Catalog

1. Wait for cache to expire (6 hrs) or delete cache file
2. Check if pathway slug is mapped in `program-list.php`
3. Check if pathway display name is mapped in `program-config.js`
4. Generate program page: `php generate-program-dynamic.php`
5. Upload and publish new page

### New Workforce Program

1. Log into `/workforce/manage-programs/`
2. Add program via web interface
3. Program appears in directory on next page load — no cache clearing needed

### After Editing JS or PHP

- JS changes: increment version number in XSL (`?v=2.1.1` → `?v=2.1.2`)
- PHP changes: delete cache file to force regeneration if needed

---

## Troubleshooting

| Problem                                     | Solution                                                                                          |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| Workforce programs duplicating in directory | Old cache still has workforce programs baked in — delete `program-list.json` from cache directory |
| Location filter not working                 | Check `data-locations` on card elements in browser inspector                                      |
| Programs missing from directory             | Check if pathway slug is in `program-list.php` pathway map                                        |
| Pathway filter showing wrong name           | Check `PATHWAY_MAP` in `program-config.js`                                                        |
| Catalog cache not updating                  | Delete `program-list.json` from cache directory                                                   |
| Workforce changes not showing               | Should show instantly — check `workforce-programs.json` exists and is valid JSON                  |
| Filters not restoring from URL              | Check JS version number is current in XSL — browser may be serving old `program-directory.js`     |

---

## Version History

### v2.1 — July 24, 2026

- Separated catalog and workforce caching architecture
- Workforce programs now always read fresh from local JSON — never cached
- Catalog cache file now contains catalog programs only
- Workforce changes now instant with no cache clearing required
- Fixed workforce duplication bug caused by merging cached + fresh workforce data

### v2.0 — April 6, 2026

- Added location filtering (Flanagan, Knight, Liston, Newport, Online)
- Added `community-planning`, `computer-science-cybersecurity`, `culinary-arts` pathway mappings
- Fixed catalog fetch to use `index.xml` instead of HTML page
- Fixed Flanagan `<strong>` heading wrapper in location regex
- Switched to slug-based location lookup map for performance
- Added `data-locations` attribute to program cards
- Shareable filter URLs now restore state on page load

### v1.0 — March 2026

- Initial release
- 98 program pages with dynamic CourseLeaf content
- PHP cache system (6hr fresh, 7 day stale)
- Directory page with search, pathway, type, A-Z, workforce category filters
- Workforce program management interface
- Department name normalization
