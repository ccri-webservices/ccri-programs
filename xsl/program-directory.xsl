<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY nbsp "&#160;">
]>
<!-- 
Kitchen Sink v2.4 - 2/14/2014

INTERIOR PAGE 
A simple page type.

Contributors: Stephen Jacobs	
Last Updated: 2/19/2016
-->
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:ou="http://omniupdate.com/XSL/Variables"
    xmlns:fn="http://omniupdate.com/XSL/Functions" xmlns:ouc="http://omniupdate.com/XSL/Variables"
    exclude-result-prefixes="ou xsl xs fn ouc">
    <xsl:import href="common.xsl" />
    <xsl:template name="template-headcode">
		<style>
			/* Mobile "Filters" toggle — same pattern as the course directory.
			   Desktop: hidden, all filters show. At 991px and below (where the
			   sidebar stacks above the results) the filters collapse behind it. */
			.filter-toggle { display: none; }

			@media (max-width: 991px) {
				.filter-toggle {
					display: flex;
					align-items: center;
					justify-content: center;
					gap: 0.5em;
					width: 100%;
					padding: 0.9em 1.25em;
					background: #fff;
					border: 1px solid #dcdcdc;
					border-radius: 12px;
					font-size: 1.1em;
					font-weight: 600;
					color: var(--ink);
					cursor: pointer;
				}
				.filter-toggle:focus-visible {
					outline: 3px solid #00703c;
					outline-offset: 2px;
				}
				.filter-toggle-icon { width: 1.2em; height: 1.2em; }
				.filter-toggle-count:not(:empty) { margin-left: 0.4em; }
				.filter-collapse { display: none; margin-top: 2em; }
				.filter-collapse.is-open { display: block; }
			}
		</style>
		</xsl:template>
	
	
	<xsl:template name="template-footcode">
	  <script src="/_resources-2025/js/program-config.js?v=2.0.5"></script>
        <script src="/_resources-2025/js/program-directory.js?v=2.0.7"></script>
        
        <script>
			(function() {

        // Fetch program data and initialize
        fetch('/_resources-2025/php/program-list.php?v=10')
            .then(response => response.json())
            .then(programs => {
                const grid = document.getElementById('grid');
                
  
programs.forEach(program => {
    const card = document.createElement('a');
    card.className = 'program-card';
    
    // Normalize the pathway name using the mapping
    const normalizedPathway = normPathway(program.pathway);
    
    // Add pathway-specific class for styling
    const pathwayClass = 'pathway-' + (program.pathway || 'unknown')
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-|-$/g, '');
    card.classList.add(pathwayClass);
    
    // Set card link based on program type
    if (program.type === 'transfer') {
        // Transfer programs link to catalog
        card.href = 'https://catalog.ccri.edu' + program.url;
    } else if (program.type === 'workforce') {
        // Workforce programs use their custom URL
        card.href = program.url;
    } else {
        // Academic programs link to local pages
        card.href = '/programs/' + program.id;
    }
    
    const firstLetter = program.title.charAt(0).toUpperCase();
    const workforceCategories = program.categories || (program.category ? [program.category] : []);
    const searchStr = [program.title, normalizedPathway, program.type].concat(workforceCategories).join(' ').toLowerCase();
    
    card.dataset.url = program.url;
    card.dataset.type = program.type;
    card.dataset.pathway = normalizedPathway;  // ← Use normalized pathway
    card.dataset.letter = firstLetter;
    card.dataset.search = searchStr;
	card.dataset.locations = (program.locations || []).join(',');
    
    // Add workforce industries if any (a program can be in several)
    if (workforceCategories.length) {
        card.dataset.workforceCategories = workforceCategories.join('|');
    }
    
    // For workforce programs, show category first, then normalized pathway name
    let firstTag, secondTag;
    if (program.type === 'workforce' &amp;&amp; program.category) {
        firstTag = program.category;
        secondTag = normalizedPathway; // ← Use normalized pathway
    } else {
        firstTag = program.type;
        secondTag = normalizedPathway; // ← Use normalized pathway
    }
    
    card.innerHTML = `
        <h3 class="program-title">${program.title}</h3>
        <div class="program-meta">
            <span class="program-type-tag">${firstTag}</span>
            <span class="program-pathway-tag">${secondTag}</span>
        </div>
    `;
    
    grid.appendChild(card);
});

                
                // Initialize directory after cards are added
                if (typeof initDirectory === 'function') {
                    initDirectory();
                }
            })
            .catch(error => {
                console.error('Error loading programs:', error);
                document.getElementById('empty').style.display = 'block';
                document.getElementById('empty').innerHTML = '<div class="ei">⚠️</div><p>Error loading programs. Please try again later.</p>';
            });
			
			})();
        </script>
	
	
	</xsl:template>
	
	
	
	
	
	
    <xsl:variable name="props-path" select="concat($ou:root, $ou:site, $dirname, $props-file)" />
    <xsl:variable name="nav-heading">
        <xsl:choose>
            <xsl:when test="doc-available($props-path)">
                <xsl:value-of
                    select="document($props-path)/document/ouc:properties[@label='config']/parameter[@name='nav-heading']" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="$ou:action!='pub'">System Message: Props File Not Found</xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:template name="page-content">
        <!-- Page Content -->
        <xsl:choose>
            <xsl:when
                test="ouc:properties[@label='config']/parameter[@name='header-type']/option[@value='full-width']/@selected='true'">
                <div class="top-one">
                    <xsl:attribute name="id">
                        <xsl:value-of
                            select="/document/ouc:properties[@label='config']/parameter[@name='header-background-color']/option[@selected='true']/@value" />
                    </xsl:attribute>
                    <div class="top-one-sec-one">
                        <xsl:call-template name="breadcrumb-navigation" />
                        <h1 id="maincontent" >
                            <xsl:value-of
                                select="tokenize(ouc:properties[@label='config']/parameter[@name='heading'], '#')[1]" />
                        </h1>
                        <div class="header-paragraph">
                            <xsl:apply-templates select="ouc:div[@label='header-paragraph']" />
                        </div>
                    </div>
                    <div class="header-image">
                        <xsl:call-template name="header-image" />
                    </div>
                </div>
            </xsl:when>
            <xsl:when
                test="ouc:properties[@label='config']/parameter[@name='header-type']/option[@value='full-width-top']/@selected='true'">
                <div class="top-one top-img">
                    <xsl:attribute name="id">
                        <xsl:value-of
                            select="/document/ouc:properties[@label='config']/parameter[@name='header-background-color']/option[@selected='true']/@value" />
                    </xsl:attribute>
                    <div class="top-one-sec-one">
                       <xsl:call-template name="breadcrumb-navigation" />
                        <h1 id="maincontent" >
                            <xsl:value-of
                                select="tokenize(ouc:properties[@label='config']/parameter[@name='heading'], '#')[1]" />
                        </h1>
                        <div class="header-paragraph">
                            <xsl:apply-templates select="ouc:div[@label='header-paragraph']" />
                        </div>
                    </div>
                    <div class="header-image">
                        <xsl:call-template name="header-image" />
                    </div>
                </div>
            </xsl:when>
            <xsl:when
                test="ouc:properties[@label='config']/parameter[@name='header-type']/option[@value='side-by-side']/@selected='true'">
                <div class="top-one top-two">
                    <xsl:attribute name="id">
                        <xsl:value-of
                            select="/document/ouc:properties[@label='config']/parameter[@name='header-background-color']/option[@selected='true']/@value" />
                    </xsl:attribute>
                    <div class="top-one-sec-one">
                        <xsl:call-template name="breadcrumb-navigation" />
                        <h1 id="maincontent" >
                            <xsl:value-of
                                select="tokenize(ouc:properties[@label='config']/parameter[@name='heading'], '#')[1]" />
                        </h1>
                        <div class="header-paragraph">
                            <xsl:apply-templates select="ouc:div[@label='header-paragraph']" />
                        </div>
                    </div>
                    <div class="header-image">
                        <xsl:call-template name="header-image" />
                    </div>
                </div>
            </xsl:when>
            <xsl:when
                test="ouc:properties[@label='config']/parameter[@name='header-type']/option[@value='side-by-side-left']/@selected='true'">
                <div class="top-one top-two banner-img-left">
                    <xsl:attribute name="id">
                        <xsl:value-of
                            select="/document/ouc:properties[@label='config']/parameter[@name='header-background-color']/option[@selected='true']/@value" />
                    </xsl:attribute>
                    <div class="top-one-sec-one">
                       <xsl:call-template name="breadcrumb-navigation" />
                        <h1 id="maincontent" >
                            <xsl:value-of
                                select="tokenize(ouc:properties[@label='config']/parameter[@name='heading'], '#')[1]" />
                        </h1>
                        <div class="header-paragraph">
                            <xsl:apply-templates select="ouc:div[@label='header-paragraph']" />
                        </div>
                    </div>
                    <div class="header-image">
                        <xsl:call-template name="header-image" />
                    </div>
                </div>
            </xsl:when>
            <xsl:when
                test="ouc:properties[@label='config']/parameter[@name='header-type']/option[@value='no-img']/@selected='true'">
				
				 <xsl:choose>
                    <xsl:when
                         test="ouc:properties[@label='config']/parameter[@name='display-background-image']/option[@value='display-background-image']/@selected='true'">
                       
						
						
						
						 <div class="top-one">
					
                    <xsl:attribute name="id">
                        <xsl:value-of
                            select="/document/ouc:properties[@label='config']/parameter[@name='header-background-color']/option[@selected='true']/@value" />
                    </xsl:attribute>
							 
							 
							 <div style="background-position: 50% {/document/ouc:properties[@label='config']/parameter[@name='background-Image-position']/option[@selected='true']/@value}%; background-image: url({/document/ouc:properties[@label='config']/parameter[@name='background-Image']})">
				 <xsl:attribute name="class">
                            <xsl:value-of
                                select="/document/ouc:properties[@label='config']/parameter[@name='display-background-image']/option[@selected='true']/@value" />
                        </xsl:attribute>
              
                    <div class="top-one-sec-one">
                       <xsl:call-template name="breadcrumb-navigation" />
                        <h1 id="maincontent" >
                            <xsl:value-of
                                select="tokenize(ouc:properties[@label='config']/parameter[@name='heading'], '#')[1]" />
                        </h1>
                        <div class="header-paragraph">
                            <xsl:apply-templates select="ouc:div[@label='header-paragraph']" />
                        </div>
                    </div>
                </div>
					 </div>	
						
						
						
                    </xsl:when>
                    <xsl:otherwise>
                         <div class="top-one">
                    <xsl:attribute name="id">
                        <xsl:value-of
                            select="/document/ouc:properties[@label='config']/parameter[@name='header-background-color']/option[@selected='true']/@value" />
                    </xsl:attribute>
				
              
                    <div class="top-one-sec-one">
                       <xsl:call-template name="breadcrumb-navigation" />
                        <h1 id="maincontent" >
                            <xsl:value-of
                                select="tokenize(ouc:properties[@label='config']/parameter[@name='heading'], '#')[1]" />
                        </h1>
                        <div class="header-paragraph">
                            <xsl:apply-templates select="ouc:div[@label='header-paragraph']" />
                        </div>
                    </div>
                </div>
                    </xsl:otherwise>
                </xsl:choose>
				 
            </xsl:when>
            <xsl:when
                test="ouc:properties[@label='config']/parameter[@name='header-type']/option[@value='no-header']/@selected='true'">
            </xsl:when>
        </xsl:choose>
        <xsl:choose>
            <xsl:when
                test="ouc:properties[@label='config']/parameter[@name='header-type']/option[@value='no-header']/@selected='true'">
             
                <div class="edit-section">
                    <xsl:attribute name="id">
                        <xsl:value-of
                            select="/document/ouc:properties[@label='config']/parameter[@name='no-nav']/option[@selected='true']/@value" />
                    </xsl:attribute>
					
				
                    <div class="menu-edit-section">
							
                        <div class="menu-edit-section-inside">
							
							<nav aria-labelledby="localnav">
                            <h3 id="localnav"
                                class="local-nav-heading local-desktop side-bar-heading">
                                <xsl:value-of select="$nav-heading" />
                            </h3>
                            <button class="mobile-local-nav-btn d-lg-none collapsed" type="button" aria-haspopup="true"
                                data-toggle="collapse" data-target="#example-collapse">
                                <span id="localnav-mobile" 
                                    class="local-nav-heading-mobile side-bar-heading">

                                    <xsl:value-of select="$nav-heading" />
                                </span>
                            </button>
                            <div id="example-collapse" class="collapse d-lg-block">
                                <div class="local-nav-box">
                                    <ul
                                        class="local-nav">
                                        <xsl:call-template name="side-navigation" />
                                    </ul>
                                </div>
                            </div>
							</nav>
                        </div>
                    </div>
                    <div class="edit-area main-edit-section">
						  
						
						<div class="no-hero-header desktop-header-view">
						
						<div class="bread-box no-header">
                   <nav aria-label="Breadcrumb Navigation">
                    <ol class="breadcrumb">
                        <xsl:call-template name="breadcrumb">
                            <xsl:with-param name="path" select="$ou:dirname" />
                        </xsl:call-template>
                    </ol>
							</nav>
                </div>
                        <h1 id="maincontent">
                            <xsl:value-of
                                select="tokenize(ouc:properties[@label='config']/parameter[@name='heading'], '#')[1]" />
                        </h1>
						
						</div>
						
						
						
						
						
						
						
					
						
						
                        <xsl:apply-templates select="ouc:div[@label='main-content']" />
                    </div>
                </div>
            </xsl:when>
            <xsl:when
                test="ouc:properties[@label='config']/parameter[@name='header-type']/option[@value='no-header']/@selected='false'">
                <div class="edit-area">
                    <div>
                        <xsl:attribute name="class">
                            <xsl:value-of
                                select="/document/ouc:properties[@label='config']/parameter[@name='sec-prenav-color']/option[@selected='true']/@value" />
                        </xsl:attribute>
                        <xsl:attribute name="id">
                            <xsl:value-of
                                select="/document/ouc:properties[@label='config']/parameter[@name='edit-sec-prenav']/option[@selected='true']/@value" />
                        </xsl:attribute>
                        <div>
                            <xsl:attribute name="class">
                                <xsl:value-of
                                    select="/document/ouc:properties[@label='config']/parameter[@name='sec-prenav-width']/option[@selected='true']/@value" />
                            </xsl:attribute>
                            <div class="fullwidth-edit-section">
                                <xsl:apply-templates select="ouc:div[@label='edit-section-prenav']" />
                            </div>
                        </div>
                    </div>
                </div>
                <div>
					<xsl:attribute name="class">
                            <xsl:value-of
                                select="/document/ouc:properties[@label='config']/parameter[@name='sec-nav-color']/option[@selected='true']/@value" />
                        </xsl:attribute>
                    <xsl:attribute name="id">
                        <xsl:value-of
                            select="/document/ouc:properties[@label='config']/parameter[@name='no-nav-sec']/option[@selected='true']/@value" />
                    </xsl:attribute>
                    <div class="edit-section">
                        <xsl:attribute name="id">
                            <xsl:value-of
                                select="/document/ouc:properties[@label='config']/parameter[@name='no-nav']/option[@selected='true']/@value" />
                        </xsl:attribute>
                        <div class="menu-edit-section">
                            <div class="menu-edit-section-inside">
								<aside class="sidebar">
    <!-- Search -->
    <div class="filter-panel">
        <div class="filter-panel-hdr"><label for="q">Search by Name</label></div>
        <div class="filter-panel-body sidebar-search">
            <input type="text" id="q" placeholder="Search programs..." oninput="goSearch()" />
        </div>
    </div>

    <!-- Mobile "Filters" toggle (hidden on desktop) — same pattern as the course directory -->
    <button type="button" class="filter-toggle" id="filterToggle" aria-expanded="false" aria-controls="filterPanel">
        <svg class="filter-toggle-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M4 7h16M7 12h10M10 17h4" stroke-linecap="round"></path></svg>
        Filters<span class="filter-toggle-count" id="filterToggleCount"></span>
    </button>

    <div class="filter-collapse" id="filterPanel">
    <!-- Filter by Pathway -->
    <div class="filter-panel">
        <div class="filter-panel-hdr"><label for="pathwayF">Filter by Pathway</label></div>
        <div class="filter-panel-body">
            <select id="pathwayF" class="sidebar-select" onchange="go()">
                <option value="">All Pathways</option>
            </select>
        </div>
    </div>

    <!-- Filter by Type -->
    <div class="filter-panel">
        <div class="filter-panel-hdr"><label for="typeF">Filter by Type</label></div>
        <div class="filter-panel-body">
            <select id="typeF" class="sidebar-select" onchange="go()">
                <option value="">All Types</option>
            </select>
        </div>
    </div>

    <div class="filter-panel">
        <div class="filter-panel-hdr"><label for="locationF">Filter by Location</label></div>
        <div class="filter-panel-body">
            <select id="locationF" class="sidebar-select" onchange="go()">
                <option value="">All Locations</option>
            </select>
        </div>
    </div>

    <!-- Filter by Workforce Category -->
    <div class="filter-panel">
        <div class="filter-panel-hdr"><label for="workforceCategoryF">Filter by Workforce Category</label></div>
        <div class="filter-panel-body">
            <select id="workforceCategoryF" class="sidebar-select" onchange="go()">
                <option value="">All Workforce Categories</option>
            </select>
        </div>
    </div>

    <!-- Filter A-Z -->
    <div class="filter-panel">
        <div class="filter-panel-hdr"><label for="azF">Filter A–Z</label></div>
        <div class="filter-panel-body">
            <select id="azF" class="sidebar-select" onchange="pickAZ(this.value)">
                <option value="">All Letters</option>
            </select>
        </div>
    </div>

    <!-- Clear Filters -->
    <button class="clear-btn" id="clearBtn" onclick="clearAll()">✕ Clear all filters</button>
    </div>
</aside>
                            </div>
                        </div>
                        <div class="edit-area main-edit-section">
                            
							
							
							
                        <!-- Results Header -->
                        <div class="results-hdr">
                            <span class="showing">Showing <strong id="cnt"></strong> of <strong id="total"></strong> programs</span>
                            <div class="chips" id="chips"></div>
                        </div>

                        <!-- Program Grid (populated by JavaScript) -->
                        <div class="program-grid" id="grid">
                            <!-- Cards will be generated by JavaScript -->
                        </div>

                        <!-- Empty State -->
                        <div id="empty">
                            <div class="ei">🔍</div>
                            <p>No programs match your search.</p>
                        </div>

                        <!-- Pagination -->
                        <div class="pager" id="pager"></div>
                    
                        </div>
                    </div>
                </div>
            </xsl:when>
        </xsl:choose>
        <div class="edit-area">
            <div>
                <xsl:attribute name="class">
                    <xsl:value-of
                        select="/document/ouc:properties[@label='config']/parameter[@name='sec-one-color']/option[@selected='true']/@value" />
                </xsl:attribute>
                <xsl:attribute name="id">
                    <xsl:value-of
                        select="/document/ouc:properties[@label='config']/parameter[@name='edit-sec-one']/option[@selected='true']/@value" />
                </xsl:attribute>
                <div>
                    <xsl:attribute name="class">
                        <xsl:value-of
                            select="/document/ouc:properties[@label='config']/parameter[@name='sec-one-width']/option[@selected='true']/@value" />
                    </xsl:attribute>
                    <div class="fullwidth-edit-section">
                        <xsl:apply-templates select="ouc:div[@label='edit-section-one']" />
                    </div>
                </div>
            </div>
            <div>
                <xsl:attribute name="class">
                    <xsl:value-of
                        select="/document/ouc:properties[@label='config']/parameter[@name='sec-two-color']/option[@selected='true']/@value" />
                </xsl:attribute>
                <xsl:attribute name="id">
                    <xsl:value-of
                        select="/document/ouc:properties[@label='config']/parameter[@name='edit-sec-two']/option[@selected='true']/@value" />
                </xsl:attribute>
                <div>
                    <xsl:attribute name="class">
                        <xsl:value-of
                            select="/document/ouc:properties[@label='config']/parameter[@name='sec-two-width']/option[@selected='true']/@value" />
                    </xsl:attribute>
                    <div class="fullwidth-edit-section">
                        <xsl:apply-templates select="ouc:div[@label='edit-section-two']" />

                    </div>
                </div>
            </div>
            <div>
                <xsl:attribute name="class">
                    <xsl:value-of
                        select="/document/ouc:properties[@label='config']/parameter[@name='sec-three-color']/option[@selected='true']/@value" />
                </xsl:attribute>
                <xsl:attribute name="id">
                    <xsl:value-of
                        select="/document/ouc:properties[@label='config']/parameter[@name='edit-sec-three']/option[@selected='true']/@value" />
                </xsl:attribute>
                <div>
                    <xsl:attribute name="class">
                        <xsl:value-of
                            select="/document/ouc:properties[@label='config']/parameter[@name='sec-three-width']/option[@selected='true']/@value" />
                    </xsl:attribute>
                    <div class="fullwidth-edit-section">
                        <xsl:apply-templates select="ouc:div[@label='edit-section-three']" />
                    </div>
                </div>
            </div>
        </div>

    </xsl:template>
</xsl:stylesheet>
