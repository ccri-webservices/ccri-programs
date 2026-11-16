/**
 * Workforce Program Directory
 * Upload to: /_resources-2025/js/workforce-directory.js
 * Styles:    /_resources-2025/css/workforce-directory.css
 *
 * Builds a searchable, filterable card grid of workforce programs inside
 * <div id="workforce-directory"></div>. Data comes from program-list.php
 * (the same feed as the main program directory), workforce programs only.
 */

(function () {
  const DATA_URL = "/_resources-2025/php/program-list.php";
  const DEFAULT_IMAGE = "/workforce/programs/images/workforce-default.webp";

  let root, searchInput, industrySelect, countEl, activeEl, chipsEl, grid, emptyEl;
  let programs = [];

  /* ══ INITIALIZATION ══ */
  function init() {
    root = document.getElementById("workforce-directory");
    if (!root) return;
    root.classList.add("wf-dir");

    fetch(DATA_URL)
      .then((response) => response.json())
      .then((data) => {
        programs = data
          .filter((p) => p.type === "workforce")
          .map((p) => ({
            ...p,
            categories: p.categories || (p.category ? [p.category] : []),
          }))
          .sort((a, b) => a.title.localeCompare(b.title));
        buildUI();
        readParams();
        render();
      })
      .catch((error) => {
        console.error("Error loading workforce programs:", error);
        root.innerHTML =
          '<p class="wf-dir-error">Programs could not be loaded. Please try again later.</p>';
      });
  }

  /* ══ UI ══ */
  function buildUI() {
    root.innerHTML = `
      <div class="wf-dir-filters" role="search" aria-label="Workforce programs">
        <div class="wf-dir-field wf-dir-search">
          <label for="wfSearch">Search</label>
          <div class="wf-dir-search-box">
            <svg aria-hidden="true" viewBox="0 0 24 24" width="18" height="18"><circle cx="11" cy="11" r="7" fill="none" stroke="currentColor" stroke-width="2"/><path d="M20 20l-4-4" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>
            <input type="search" id="wfSearch" placeholder="Search programs, e.g. welding, CDL, GED" autocomplete="off">
          </div>
        </div>
        <div class="wf-dir-field wf-dir-industry">
          <label for="wfIndustry">Industry</label>
          <select id="wfIndustry"><option value="">All industries</option></select>
        </div>
        <div class="wf-dir-active" id="wfActive" hidden>
          <div class="wf-dir-chips" id="wfChips"></div>
          <button type="button" class="wf-dir-clear-all" id="wfClearAll">× Clear all filters</button>
        </div>
      </div>
      <h2 class="wf-dir-count" id="wfCount" aria-live="polite"></h2>
      <div class="wf-dir-grid" id="wfGrid"></div>
      <div class="wf-dir-empty" id="wfEmpty" hidden>
        <p>No programs match your search.</p>
        <button type="button" class="wf-dir-clear" id="wfClear">Clear filters</button>
      </div>
    `;

    searchInput = document.getElementById("wfSearch");
    industrySelect = document.getElementById("wfIndustry");
    countEl = document.getElementById("wfCount");
    activeEl = document.getElementById("wfActive");
    chipsEl = document.getElementById("wfChips");
    grid = document.getElementById("wfGrid");
    emptyEl = document.getElementById("wfEmpty");

    // Industry options — every industry in use, A–Z
    const industries = [...new Set(programs.flatMap((p) => p.categories))].sort(
      (a, b) => a.localeCompare(b),
    );
    industries.forEach((industry) => {
      const o = document.createElement("option");
      o.value = o.textContent = industry;
      industrySelect.appendChild(o);
    });

    searchInput.addEventListener("input", () => {
      render();
      pushParams();
    });
    industrySelect.addEventListener("change", () => {
      render();
      pushParams();
    });
    document.getElementById("wfClear").addEventListener("click", clearAll);
    document.getElementById("wfClearAll").addEventListener("click", clearAll);
  }

  function clearAll() {
    searchInput.value = "";
    industrySelect.value = "";
    render();
    pushParams();
    searchInput.focus();
  }

  /* Active filter chips + "Clear all" (inside the filter box, like the
     course directory) — click a chip to remove that filter */
  function renderChips(q, industry) {
    const chips = [];
    if (industry)
      chips.push(
        makeChip("Industry: " + industry, () => {
          industrySelect.value = "";
        }),
      );
    if (q)
      chips.push(
        makeChip("Search: " + q, () => {
          searchInput.value = "";
        }),
      );
    chipsEl.replaceChildren(...chips);
    activeEl.hidden = chips.length === 0;
  }

  function makeChip(label, clear) {
    const chip = document.createElement("button");
    chip.type = "button";
    chip.className = "wf-dir-chip";
    chip.setAttribute("aria-label", "Remove filter: " + label);
    chip.textContent = label + " ";
    const x = document.createElement("span");
    x.className = "wf-dir-chip-x";
    x.setAttribute("aria-hidden", "true");
    x.textContent = "×";
    chip.appendChild(x);
    chip.addEventListener("click", () => {
      clear();
      render();
      pushParams();
      searchInput.focus();
    });
    return chip;
  }

  /* ══ FILTER + RENDER ══ */
  function render() {
    const q = searchInput.value.trim().toLowerCase();
    const industry = industrySelect.value;

    const matches = programs.filter((p) => {
      if (industry && !p.categories.includes(industry)) return false;
      if (!q) return true;
      return [p.title, p.description || "", ...p.categories]
        .join(" ")
        .toLowerCase()
        .includes(q);
    });

    countEl.textContent =
      matches.length + (matches.length === 1 ? " program found" : " programs found");
    renderChips(searchInput.value.trim(), industry);
    grid.replaceChildren(...matches.map((p) => makeCard(p, industry)));
    emptyEl.hidden = matches.length > 0;
  }

  function makeCard(program, activeIndustry) {
    const card = document.createElement("a");
    card.className = "wf-dir-card";
    card.href = program.url;

    const img = document.createElement("img");
    img.className = "wf-dir-card-img";
    img.src = program.image || DEFAULT_IMAGE;
    img.alt = ""; // decorative — the title names the link
    img.loading = "lazy";
    img.width = 900;
    img.height = 600;
    img.addEventListener("error", () => {
      if (img.src.indexOf(DEFAULT_IMAGE) === -1) img.src = DEFAULT_IMAGE;
    });
    card.appendChild(img);

    // Show the filtered industry when one is selected, otherwise the first
    const eyebrow = document.createElement("span");
    eyebrow.className = "wf-dir-card-industry";
    eyebrow.textContent = activeIndustry || program.categories[0] || "";
    card.appendChild(eyebrow);

    const title = document.createElement("h3");
    title.className = "wf-dir-card-title";
    title.textContent = program.title;
    card.appendChild(title);

    if (program.description) {
      const desc = document.createElement("p");
      desc.className = "wf-dir-card-desc";
      desc.textContent = program.description;
      card.appendChild(desc);
    }

    return card;
  }

  /* ══ URL ↔ STATE ══ */
  function readParams() {
    const p = new URLSearchParams(window.location.search);
    searchInput.value = p.get("q") || "";
    const industry = p.get("industry") || "";
    if ([...industrySelect.options].some((o) => o.value === industry))
      industrySelect.value = industry;
  }

  function pushParams() {
    const p = new URLSearchParams();
    if (searchInput.value.trim()) p.set("q", searchInput.value.trim());
    if (industrySelect.value) p.set("industry", industrySelect.value);
    const qs = p.toString();
    history.replaceState(null, "", qs ? "?" + qs : window.location.pathname);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
