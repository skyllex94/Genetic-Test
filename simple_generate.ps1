# Clean post generation script
$postsDir = "D:\GenTest\Genetic-Test\blog"
$outputDir = "D:\GenTest\Genetic-Test\blog-posts"
$mainHtml = "D:\GenTest\Genetic-Test\blog.html"

# Create output directory
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

# Read header/footer from blog.html
$html = Get-Content $mainHtml -Raw -Encoding UTF8
$headerEnd = $html.IndexOf("<!-- Blog Posts -->")
$footerStart = $html.IndexOf("<!-- Back to Home Button -->")
$header = $html.Substring(0, $headerEnd)
$footer = $html.Substring($footerStart)
Write-Host "Got header/footer"

# Get post files
$postFiles = Get-ChildItem $postsDir -Filter "post_*.html" | Sort-Object Name
Write-Host "Processing $($postFiles.Count) posts..."

$allPosts = @()

foreach ($file in $postFiles) {
    if ($file.Name -notmatch 'post_(\d+)\.html$') { continue }
    $postId = $matches[1]
    
    # Read with windows-1251 encoding
    $bytes = Get-Content $file.FullName -Encoding Byte
    $postHtml = [System.Text.Encoding]::GetEncoding("windows-1251").GetString($bytes)
    
    # Extract title
    $titleMatch = [regex]::Match($postHtml, '<title>([^<]+) ::')
    if ($titleMatch.Success) {
        $title = $titleMatch.Groups[1].Value.Trim()
    } else {
        $title = "No Title"
    }
    
    # Extract date
    $dateMatch = [regex]::Match($postHtml, '\d{2}\.\d{2}\.\d{4} \d{2}:\d{2}')
    if ($dateMatch.Success) {
        $date = $dateMatch.Value
    } else {
        $date = ""
    }
    
    # Find content start - look for date then next HTML tag
    $contentStart = $postHtml.IndexOf($date)
    if ($contentStart -lt 0) { $contentStart = 200 }
    $contentStart = $postHtml.IndexOf("<", $contentStart)
    if ($contentStart -lt 0) { $contentStart = 200 }
    
    # Find content end - before comments section
    $contentEnd = $postHtml.IndexOf("comments", $contentStart)
    if ($contentEnd -lt 0) { $contentEnd = $postHtml.IndexOf("Коментари", $contentStart) }
    if ($contentEnd -lt 0) { $contentEnd = $postHtml.Length - 1 }
    
    $content = $postHtml.Substring($contentStart, $contentEnd - $contentStart)
    
    # Remove script tags
    $content = [regex]::Replace($content, '<script[^>]*>.*?</script>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    # Remove style tags
    $content = [regex]::Replace($content, '<style[^>]*>.*?</style>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    # Remove images
    $content = [regex]::Replace($content, '<img[^>]*>', '', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    # Remove blog.bg specific divs (ads, etc.)
    $content = [regex]::Replace($content, '<div[^>]*id="(ado|fb|twitter)[^"]*"[^>]*>.*?</div>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    # Remove form tags
    $content = [regex]::Replace($content, '<form[^>]*>.*?</form>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    # Remove blog.bg links
    $content = [regex]::Replace($content, 'href="https://bliznaci\.blog\.bg/[^"]*"', 'href="#"')
    
    # Create excerpt (plain text, first 200 chars)
    $plainText = [regex]::Replace($content, '<[^>]+>', '')
    $plainText = [regex]::Replace($plainText, '\s+', ' ').Trim()
    if ($plainText.Length -gt 200) {
        $excerpt = $plainText.Substring(0, 200) + "..."
    } else {
        $excerpt = $plainText
    }
    
    # Generate slug from title
    $slug = $title.ToLower()
    $slug = [regex]::Replace($slug, '[^a-z0-9\u0400-\u04FF]+', '-')
    $slug = [regex]::Replace($slug, '-+', '-').Trim('-')
    if ([string]::IsNullOrEmpty($slug)) { $slug = "post-$postId" }
    $postFileName = "$slug.html"
    $postUrl = "/blog-posts/$postFileName"
    
    # Create post page (UTF-8)
    $postPage = $header
    $postPage += "<section class=`"py-5`"><div class=`"container`"><div class=`"row`"><div class=`"col-lg-8 mx-auto`"><article class=`"card shadow`"><div class=`"card-body`">"
    $postPage += "<h1 class=`"card-title mb-3`">$title</h1>"
    $postPage += "<div class=`"mb-3 text-muted`"><small>Публикувано на: $date</small></div>"
    $postPage += "<div class=`"blog-content`">$content</div>"
    $postPage += "<div class=`"mt-4`"><a href=`"../blog.html`" class=`"btn btn-outline-primary`">&larr; Обратно към блога</a></div>"
    $postPage += "</div></article></div></div></section>"
    $postPage += $footer
    
    $postPagePath = Join-Path $outputDir $postFileName
    $postPage | Out-File -FilePath $postPagePath -Encoding UTF8
    Write-Host "Created: $postFileName"
    
    $allPosts += [PSCustomObject]@{
        Title = $title
        Date = $date
        Excerpt = $excerpt
        Url = $postUrl
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
Write-Host "Done! Created $($allPosts.Count) post pages and updated blog.html"
