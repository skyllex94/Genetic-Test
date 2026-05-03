# Script to generate individual blog post pages and update blog.html
$blogDir = "D:\GenTest\Genetic-Test\blog"
$outputDir = "D:\GenTest\Genetic-Test\blog-posts"
$mainBlogHtml = "D:\GenTest\Genetic-Test\blog.html"
$imgBlogDir = "D:\GenTest\Genetic-Test\img\blog"

# Create output directory
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
Write-Host "Created output directory: $outputDir"

# Read the header and footer from existing blog.html
$html = Get-Content $mainBlogHtml -Raw
$headerEnd = $html.IndexOf("<!-- Blog Posts -->")
$footerStart = $html.IndexOf("<!-- Back to Home Button -->")

if ($headerEnd -gt 0 -and $footerStart -gt 0) {
    $header = $html.Substring(0, $headerEnd)
    $footer = $html.Substring($footerStart)
    Write-Host "Extracted header and footer from blog.html"
} else {
    Write-Warning "Could not find markers in blog.html"
    exit 1
}

# Get all post files
$postFiles = Get-ChildItem $blogDir -Filter "post_*.html" | Sort-Object Name
Write-Host "Found $($postFiles.Count) post files to process"

# Array to store post info for blog.html update
$allPosts = @()

foreach ($file in $postFiles) {
    # Extract post ID
    if ($file.Name -match 'post_(\d+)\.html') {
        $postId = $matches[1]
    } else {
        continue
    }
    
    # Read post HTML with correct encoding
    $bytes = Get-Content $file.FullName -Encoding Byte
    $postHtml = [System.Text.Encoding]::GetEncoding("windows-1251").GetString($bytes)
    
    # Extract title
    $titleMatch = [regex]::Match($postHtml, '<title>([^<]+) ::')
    $title = if ($titleMatch.Success) { $titleMatch.Groups[1].Value.Trim() } else { "Без заглавие" }
    
    # Extract date
    $dateMatch = [regex]::Match($postHtml, '(\d{2}\.\d{2}\.(\d{4}|\d{2}) \d{2}:\d{2}) -')
    $date = if ($dateMatch.Success) { $dateMatch.Groups[1].Value } else { "" }
    
    # Extract first image (for later use)
    $imgMatch = [regex]::Match($postHtml, 'src="(/photos/173622/[^"]+)"')
    $firstImage = if ($imgMatch.Success) { $imgMatch.Groups[1].Value } else { "" }
    
    # Extract content - find the main content area
    # Look for content after the date line
    $contentStart = $postHtml.IndexOf($date)
    if ($contentStart -gt 0) {
        # Find where content starts (after date and any images)
        $tempStart = $postHtml.IndexOf("<", $contentStart)
        if ($tempStart -gt 0) { $contentStart = $tempStart }
        
        # Find where content ends (before comments or footer)
        $contentEnd = $postHtml.IndexOf("Коментари", $contentStart)
        if ($contentEnd -lt 0) { $contentEnd = $postHtml.IndexOf("comments", $contentStart) }
        if ($contentEnd -lt 0) { $contentEnd = $postHtml.Length - 1 }
        
        $content = $postHtml.Substring($contentStart, $contentEnd - $contentStart)
        
        # Clean up the content - remove scripts, styles, ads
        $content = [regex]::Replace($content, '<script[^>]*>.*?</script>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $content = [regex]::Replace($content, '<style[^>]*>.*?</style>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $content = [regex]::Replace($content, '<div[^>]*id="(ado|fb|twitter)[^"]*"[^>]*>.*?</div>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $content = [regex]::Replace($content, '<form[^>]*>.*?</form>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        
        # Remove images (as requested)
        $content = [regex]::Replace($content, '<img[^>]*>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        
        # Replace any remaining blog.bg links
        $content = [regex]::Replace($content, 'href="https://bliznaci\.blog\.bg/[^"]*"', 'href="#"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    } else {
        $content = "<p>Съдържанието ще бъде добавено скоро.</p>"
    }
    
    # Create excerpt (first 300 characters)
    $plainText = [regex]::Replace($content, '<[^>]+>', '')
    $plainText = [regex]::Replace($plainText, '\s+', ' ').Trim()
    $excerpt = if ($plainText.Length -gt 300) { $plainText.Substring(0, 300) + "..." } else { $plainText }
    
    # Generate post slug from title (for URL-friendly filename)
    $slug = $title.ToLower()
    $slug = [regex]::Replace($slug, '[^a-z0-9\u0400-\u04FF]+', '-')
    $slug = [regex]::Replace($slug, '-+', '-')
    $slug = $slug.Trim('-')
    if ([string]::IsNullOrEmpty($slug)) { $slug = "post-$postId" }
    
    $postFileName = "$slug.html"
    $postUrl = "/blog-posts/$postFileName"
    
    # Create individual post page
    $postPageHtml = $header
    $postPageHtml += @"
    <section class="py-5">
        <div class="container">
            <div class="row">
                <div class="col-lg-8 mx-auto">
                    <article class="card shadow">
                        <div class="card-body">
                            <h1 class="card-title mb-3">$title</h1>
                            <div class="mb-3 text-muted">
                                <small>Публикувано на: $date</small>
                            </div>
                            <div class="blog-content">
                                $content
                            </div>
                            <div class="mt-4">
                                <a href="../blog.html" class="btn btn-outline-primary">&larr; Обратно към блога</a>
                            </div>
                        </div>
                    </article>
                </div>
            </div>
        </div>
    </section>
"@
    $postPageHtml += $footer
    
    # Save post page
    $postPagePath = Join-Path $outputDir $postFileName
    $postPageHtml | Out-File -FilePath $postPagePath -Encoding UTF8
    Write-Host "Created post page: $postFileName"
    
    # Store post info
    $postInfo = [PSCustomObject]@{
        Title = $title
        Date = $date
        Excerpt = $excerpt
        Url = $postUrl
        FileName = $postFileName
        PostId = $postId
    }
    $allPosts += $postInfo
}

# Now update blog.html to show excerpts with "Read More" buttons
Write-Host "Updating blog.html with excerpts and Read More buttons..."

$newBlogContent = $header
$newBlogContent += @"
    <section class="py-5">
        <div class="container">
            <div class="row">
                <div class="col-12">
                    <h1 class="text-center mb-4">Блог</h1>
                    <p class="text-center mb-5 lead">Тук споделям моите разработки, открития и мисли за дерматоглификата и човешкия потенциал.</p>
                </div>
            </div>

            <!-- Blog Posts -->
            <div class="row">
"@

$postCount = 0
foreach ($post in $allPosts) {
    $postCount++
    $newBlogContent += @"
                <!-- Blog Post $postCount -->
                <div class="col-12 mb-5">
                    <article class="card shadow">
                        <div class="card-body">
                            <h2 class="card-title mb-3">$($post.Title)</h2>
                            <div class="mb-3 text-muted">
                                <small>Публикувано на: $($post.Date)</small>
                            </div>
                            <div class="blog-content">
                                <p>$($post.Excerpt)</p>
                            </div>
                            <div class="mt-3">
                                <a href="$($post.Url)" target="_blank" class="btn btn-primary">Прочети повече &rarr;</a>
                            </div>
                        </div>
                    </article>
                </div>
"@
}

$newBlogContent += @"
            </div>

            <!-- Back to Home Button -->
            <div class="row mt-4">
                <div class="col-12 text-center">
                    <a href="index.html" class="btn btn-outline-primary">Обратно към началната страница</a>
                </div>
            </div>
        </div>
    </section>
"@
$newBlogContent += $footer

# Save updated blog.html
$newBlogContent | Out-File -FilePath $mainBlogHtml -Encoding UTF8
Write-Host "Updated blog.html with $postCount posts (excerpts with Read More buttons)"

Write-Host "Done! Generated $($allPosts.Count) individual post pages in $outputDir"
