# Script to regenerate posts with proper encoding and without metadata
$postsDir = "D:\GenTest\Genetic-Test\blog"
$outputDir = "D:\GenTest\Genetic-Test\blog-posts"
$mainBlogHtml = "D:\GenTest\Genetic-Test\blog.html"

# Create output directory
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
Write-Host "Step 1: Reading blog.html header/footer..."
$html = Get-Content $mainBlogHtml -Raw -Encoding UTF8
$headerEnd = $html.IndexOf("<!-- Blog Posts -->")
$footerStart = $html.IndexOf("<!-- Back to Home Button -->")
if ($headerEnd -gt 0 -and $footerStart -gt 0) {
    $header = $html.Substring(0, $headerEnd)
    $footer = $html.Substring($footerStart)
    Write-Host "OK - got header/footer"
} else {
    Write-Host "ERROR: markers not found in blog.html"
    exit 1
}

# Get all post files
$postFiles = Get-ChildItem $postsDir -Filter "post_*.html" | Sort-Object Name
Write-Host "Processing $($postFiles.Count) posts..."

$allPosts = @()

foreach ($file in $postFiles) {
    # Extract post ID
    if ($file.Name -match 'post_(\d+)\.html$') {
        $postId = $matches[1]
    } else {
        continue
    }
    
    # Read with windows-1251 encoding
    $bytes = Get-Content $file.FullName -Encoding Byte
    $postHtml = [System.Text.Encoding]::GetEncoding("windows-1251").GetString($bytes)
    
    # Extract title from title tag
    $titleMatch = [regex]::Match($postHtml, '<title>([^<]+) ::')
    $title = if ($titleMatch.Success) { 
        $titleMatch.Groups[1].Value.Trim() 
    } else { 
        "Без заглавие" 
    }
    
    # Extract date
    $dateMatch = [regex]::Match($postHtml, '(\d{2}\.\d{2}\.(\d{4}|\d{2}) \d{2}:\d{2}) -')
    $date = if ($dateMatch.Success) { $dateMatch.Groups[1].Value } else { "" }
    
    # Find content start (after date line)
    $contentStart = $postHtml.IndexOf($date)
    if ($contentStart -lt 0) { $contentStart = 200 }
    $contentStart = $postHtml.IndexOf("<", $contentStart)
    if ($contentStart -lt 0) { $contentStart = 200 }
    
    # Find content end (before comments section)
    $contentEnd = $postHtml.IndexOf("comments", $contentStart)
    if ($contentEnd -lt 0) { $contentEnd = $postHtml.IndexOf("Коментари", $contentStart) }
    if ($contentEnd -lt 0) { $contentEnd = $postHtml.Length - 1 }
    
    $content = $postHtml.Substring($contentStart, $contentEnd - $contentStart)
    
    # Remove script tags
    $content = [regex]::Replace($content, '<script[^>]*>.*?</script>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    # Remove style tags
    $content = [regex]::Replace($content, '<style[^>]*>.*?</style>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    # Remove images (as requested)
    $content = [regex]::Replace($content, '<img[^>]*>', '', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    # Remove metadata lines (Автор, Категория, Прочетен, etc.)
    $content = [regex]::Replace($content, '<div[^>]*>Автор:.*?</div>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $content = [regex]::Replace($content, 'Автор:.*?<br\s*/?>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $content = [regex]::Replace($content, 'Категория:.*?<br\s*/?>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $content = [regex]::Replace($content, 'Прочетен:.*?<br\s*/?>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $content = [regex]::Replace($content, 'Коментари:.*?<br\s*/?>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $content = [regex]::Replace($content, 'Гласове:.*?<br\s*/?>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    # Remove blog.bg specific divs
    $content = [regex]::Replace($content, '<div[^>]*id="(ado|fb|twitter)[^"]*"[^>]*>.*?</div>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    # Remove form tags
    $content = [regex]::Replace($content, '<form[^>]*>.*?</form>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    # Replace blog.bg links with #
    $content = [regex]::Replace($content, 'href="https://bliznaci\.blog\.bg/[^"]*"', 'href="#"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    
    # Create excerpt (first 250 chars, plain text)
    $plainText = [regex]::Replace($content, '<[^>]+>', '')
    $plainText = [regex]::Replace($plainText, '\s+', ' ').Trim()
    $excerpt = if ($plainText.Length -gt 250) { $plainText.Substring(0, 250) + "..." } else { $plainText }
    
    # Generate slug from title
    $slug = $title.ToLower()
    $slug = [regex]::Replace($slug, '[^a-z0-9\u0400-\u04FF]+', '-')
    $slug = [regex]::Replace($slug, '-+', '-').Trim('-')
    if ([string]::IsNullOrEmpty($slug)) { $slug = "post-$postId" }
    
    $postFileName = "$slug.html"
    $postUrl = "/blog-posts/$postFileName"
    
    # Create individual post page (UTF-8)
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
    
    $postPagePath = Join-Path $outputDir $postFileName
    $postPageHtml | Out-File -FilePath $postPagePath -Encoding UTF8
    Write-Host "Created: $postFileName"
    
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

# Update blog.html with excerpts and Read More buttons
Write-Host "Updating blog.html..."
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

$newBlogContent | Out-File -FilePath $mainBlogHtml -Encoding UTF8
Write-Host "Done! Created $($allPosts.Count) post pages and updated blog.html"
