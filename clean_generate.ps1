# Script to regenerate posts - simple version
$postsDir = "D:\GenTest\Genetic-Test\blog"
$outputDir = "D:\GenTest\Genetic-Test\blog-posts"
$mainHtml = "D:\GenTest\Genetic-Test\blog.html"

# Create output dir
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

# Read header/footer from existing blog.html
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
    
    # Read as bytes then convert from windows-1251
    $bytes = Get-Content $file.FullName -Encoding Byte
    $postHtml = [System.Text.Encoding]::GetEncoding("windows-1251").GetString($bytes)
    
    # Extract title
    $titleMatch = [regex]::Match($postHtml, '<title>([^<]+) ::')
    $title = if ($titleMatch.Success) { $titleMatch.Groups[1].Value.Trim() } else { "Без заглавие" }
    
    # Extract date
    $dateMatch = [regex]::Match($postHtml, '\d{2}\.\d{2}\.\d{4} \d{2}:\d{2}')
    $date = if ($dateMatch.Success) { $dateMatch.Value } else { "" }
    
    # Find content area - start after date
    $contentStart = $postHtml.IndexOf($date)
    if ($contentStart -lt 0) { $contentStart = 200 }
    $contentStart = $postHtml.IndexOf("<", $contentStart)
    if ($contentStart -lt 0) { $contentStart = 200 }
    
    # Find end - before comments section
    $contentEnd = $postHtml.IndexOf("comments", $contentStart)
    if ($contentEnd -lt 0) { $contentEnd = $postHtml.IndexOf("Коментари", $contentStart) }
    if ($contentEnd -lt 0) { $contentEnd = $postHtml.Length - 1 }
    
    $content = $postHtml.Substring($contentStart, $contentEnd - $contentStart)
    
    # Remove scripts, styles, forms
    $content = [regex]::Replace($content, '<script[^>]*>.*?</script>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $content = [regex]::Replace($content, '<style[^>]*>.*?</style>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $content = [regex]::Replace($content, '<form[^>]*>.*?</form>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $content = [regex]::Replace($content, '<img[^>]*>', '', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    
    # Remove metadata divs (Author, Category, etc.)
    $content = [regex]::Replace($content, '<div[^>]*>Автор:.*?</div>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $content = [regex]::Replace($content, '<div[^>]*>Категория:.*?</div>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    # Remove blog.bg specific divs
    $content = [regex]::Replace($content, '<div[^>]*id="(ado|fb|twitter)[^"]*"[^>]*>.*?</div>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    # Create excerpt
    $plainText = [regex]::Replace($content, '<[^>]+>', '')
    $plainText = [regex]::Replace($plainText, '\s+', ' ').Trim()
    $excerpt = if ($plainText.Length -gt 200) { $plainText.Substring(0, 200) + "..." } else { $plainText }
    
    # Generate filename from title
    $slug = $title.ToLower()
    $slug = [regex]::Replace($slug, '[^a-z0-9\u0400-\u04FF]+', '-')
    $slug = [regex]::Replace($slug, '-+', '-').Trim('-')
    if ([string]::IsNullOrEmpty($slug)) { $slug = "post-$postId" }
    $postFileName = "$slug.html"
    $postUrl = "/blog-posts/$postFileName"
    
    # Create post page
    $postPage = $header
    $postPage += "<section class=`"py-5`"><div class=`"container`"><div class=`"row`"><div class=`"col-lg-8 mx-auto`"><article class=`"card shadow`"><div class=`"card-body`">"
    $postPage += "<h1 class=`"card-title mb-3`">$title</h1>"
    $postPage += "<div class=`"mb-3 text-muted`"><small>Публикувано на: $date</small></div>"
    $postPage += "<div class=`"blog-content`">$content</div>"
    $postPage += "<div class=`"mt-4`"><a href=`"../blog.html`" class=`"btn btn-outline-primary`">&larr; Обратно към блога</a></div>"
    $postPage += "</div></article></div></div></section>"
    $postPage += $footer
    
    $postPage | Out-File -FilePath (Join-Path $outputDir $postFileName) -Encoding UTF8
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
