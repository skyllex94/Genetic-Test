# Simple blog generation
$postsDir = "D:\GenTest\Genetic-Test\blog"
$outputDir = "D:\GenTest\Genetic-Test\blog-posts"
$mainHtml = "D:\GenTest\Genetic-Test\blog.html"

# Create output
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

# Read blog.html
$html = Get-Content $mainHtml -Raw -Encoding UTF8
$headerEnd = $html.IndexOf("<!-- Blog Posts -->")
$footerStart = $html.IndexOf("<!-- Back to Home Button -->")
$header = $html.Substring(0, $headerEnd)
$footer = $html.Substring($footerStart)

# Get post files
$postFiles = Get-ChildItem $postsDir -Filter "post_*.html" | Sort-Object Name
Write-Host "Found $($postFiles.Count) posts"

$allPosts = @()

foreach ($file in $postFiles) {
    if ($file.Name -notmatch 'post_(\d+)\.html$') { continue }
    $postId = $matches[1]
    
    # Read as bytes, convert from windows-1251
    $bytes = Get-Content $file.FullName -Encoding Byte
    $content = [System.Text.Encoding]::GetEncoding("windows-1251").GetString($bytes)
    
    # Extract title
    $tStart = $content.IndexOf("<title>")
    $tEnd = $content.IndexOf(" ::")
    if ($tStart -ge 0 -and $tEnd -ge 0) {
        $title = $content.Substring($tStart + 7, $tEnd - $tStart - 7).Trim()
    } else {
        $title = "No Title"
    }
    
    # Extract date
    $date = ""
    $lines = $content -split "`n"
    foreach ($line in $lines) {
        if ($line -match '\d{2}\.\d{2}\.\d{4} \d{2}:\d{2}') {
            $date = $matches[0]
            break
        }
    }
    
    # Get content after date
    $startIdx = $content.IndexOf($date)
    if ($startIdx -lt 0) { $startIdx = 200 }
    $startIdx = $content.IndexOf("<", $startIdx)
    if ($startIdx -lt 0) { $startIdx = 200 }
    
    # Find end (before comments)
    $endIdx = $content.IndexOf("comments", $startIdx)
    if ($endIdx -lt 0) { $endIdx = $content.IndexOf("Коментари", $startIdx) }
    if ($endIdx -lt 0) { $endIdx = $content.Length - 1 }
    
    $body = $content.Substring($startIdx, $endIdx - $startIdx)
    
    # Remove scripts and styles
    $body = [regex]::Replace($body, '<script[^>]*>.*?</script>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $body = [regex]::Replace($body, '<style[^>]*>.*?</style>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $body = [regex]::Replace($body, '<img[^>]*>', '', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $body = [regex]::Replace($body, '<form[^>]*>.*?</form>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    # Create excerpt
    $plain = [regex]::Replace($body, '<[^>]+>', '')
    $plain = [regex]::Replace($plain, '\s+', ' ').Trim()
    if ($plain.Length -gt 200) {
        $excerpt = $plain.Substring(0, 200) + "..."
    } else {
        $excerpt = $plain
    }
    
    # Filename from title
    $slug = $title.ToLower()
    $slug = [regex]::Replace($slug, '[^a-z0-9\u0400-\u04FF]+', '-')
    $slug = [regex]::Replace($slug, '-+', '-').Trim('-')
    if ([string]::IsNullOrEmpty($slug)) { $slug = "post-$postId" }
    
    $fileName = "$slug.html"
    $url = "/blog-posts/$fileName"
    
    # Create post page
    $page = $header
    $page += "<section class=`"py-5`"><div class=`"container`"><div class=`"row`"><div class=`"col-lg-8 mx-auto`"><article class=`"card shadow`"><div class=`"card-body`">"
    $page += "<h1 class=`"card-title mb-3`">$title</h1>"
    $page += "<div class=`"mb-3 text-muted`"><small>Публикувано на: $date</small></div>"
    $page += "<div class=`"blog-content`">$body</div>"
    $page += "<div class=`"mt-4`"><a href=`"../blog.html`" class=`"btn btn-outline-primary`">&larr; Обратно към блога</a></div>"
    $page += "</div></article></div></div></section>"
    $page += $footer
    
    $page | Out-File -FilePath (Join-Path $outputDir $fileName) -Encoding UTF8
    Write-Host "Created: $fileName"
    
    $allPosts += [PSCustomObject]@{
        Title = $title
        Date = $date
        Excerpt = $excerpt
        Url = $url
    }
}

# Update blog.html
Write-Host "Updating blog.html..."
$newBlog = $header
$newBlog += "<section class=`"py-5`"><div class=`"container`"><div class=`"row`"><div class=`"col-12`"><h1 class=`"text-center mb-4`">Блог</h1><p class=`"text-center mb-5 lead`">Тук споделям моите разработки, открития и мисли за дерматоглификата и човешкия потенциал.</p></div></div>"
$newBlog += "<!-- Blog Posts --><div class=`"row`">"

$pc = 0
foreach ($post in $allPosts) {
    $pc++
    $newBlog += "<div class=`"col-12 mb-5`"><article class=`"card shadow`"><div class=`"card-body`"><h2 class=`"card-title mb-3`">$($post.Title)</h2><div class=`"mb-3 text-muted`"><small>Публикувано на: $($post.Date)</small></div><div class=`"blog-content`"><p>$($post.Excerpt)</p></div><div class=`"mt-3`"><a href=`"$($post.Url)`" target=`"_blank`" class=`"btn btn-primary`">Прочети повече &rarr;</a></div></div></article></div>"
}

$newBlog += "</div><!-- Back to Home Button --><div class=`"row mt-4`"><div class=`"col-12 text-center`"><a href=`"index.html`" class=`"btn btn-outline-primary`">Обратно към началната страница</a></div></div></div></section>"
$newBlog += $footer

$newBlog | Out-File -FilePath $mainHtml -Encoding UTF8
Write-Host "Done! Created $($allPosts.Count) pages and updated blog.html"
