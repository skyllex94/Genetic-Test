$postsDir = "D:\GenTest\Genetic-Test\blog"
$outputDir = "D:\GenTest\Genetic-Test\blog-posts"
$mainHtml = "D:\GenTest\Genetic-Test\blog.html"

# Create output directory
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
    $titleMatch = [regex]::Match($content, '<title>([^<]+) ::')
    $title = if ($titleMatch.Success) { $titleMatch.Groups[1].Value.Trim() } else { "No Title" }
    
    # Extract date
    $dateMatch = [regex]::Match($content, '\d{2}\.\d{2}\.\d{4} \d{2}:\d{2}')
    $date = if ($dateMatch.Success) { $dateMatch.Value } else { "" }
    
    # Find content start
    $start = $content.IndexOf($date)
    if ($start -lt 0) { $start = 200 }
    $start = $content.IndexOf("<", $start)
    if ($start -lt 0) { $start = 200 }
    
    # Find content end
    $end = $content.IndexOf("comments", $start)
    if ($end -lt 0) { $end = $content.IndexOf("----------", $start) }
    if ($end -lt 0) { $end = $content.Length - 1 }
    
    $body = $content.Substring($start, $end - $start)
    
    # Remove scripts and styles
    $body = [regex]::Replace($body, '<script[^>]*>.*?</script>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $body = [regex]::Replace($body, '<style[^>]*>.*?</style>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $body = [regex]::Replace($body, '<img[^>]*>', '', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    
    # Create excerpt
    $plain = [regex]::Replace($body, '<[^>]+>', '')
    $plain = [regex]::Replace($plain, '\s+', ' ').Trim()
    $excerpt = if ($plain.Length -gt 200) { $plain.Substring(0, 200) + "..." } else { $plain }
    
    # Create filename
    $slug = $title.ToLower()
    $slug = [regex]::Replace($slug, '[^a-z0-9]+', '-')
    $slug = [regex]::Replace($slug, '-+', '-').Trim('-')
    if ([string]::IsNullOrEmpty($slug)) { $slug = "post-$postId" }
    
    $fileName = "$slug.html"
    $url = "/blog-posts/$fileName"
    
    # Create post page
    $page = $header
    $page += "<section class='py-5'><div class='container'><div class='row'><div class='col-lg-8 mx-auto'><article class='card shadow'><div class='card-body'>"
    $page += "<h1 class='card-title mb-3'>$title</h1>"
    $page += "<div class='mb-3 text-muted'><small>Date: $date</small></div>"
    $page += "<div class='blog-content'>$body</div>"
    $page += "<div class='mt-4'><a href='../blog.html' class='btn btn-outline-primary'>&larr; Back to Blog</a></div>"
    $page += "</div></article></div></div></section>"
    $page += $footer
    
    $page | Out-File -FilePath (Join-Path $outputDir $fileName) -Encoding UTF8
    Write-Host "Created: $fileName"
    
    $allPosts += @{ Title = $title; Date = $date; Excerpt = $excerpt; Url = $url }
}

# Update blog.html
Write-Host "Updating blog.html..."
$newBlog = $header
$newBlog += "<section class='py-5'><div class='container'><div class='row'><div class='col-12'><h1 class='text-center mb-4'>Blog</h1><p class='text-center mb-5 lead'>Welcome to my blog.</p></div></div>"
$newBlog += "<!-- Blog Posts --><div class='row'>"

$pc = 0
foreach ($post in $allPosts) {
    $pc++
    $newBlog += "<div class='col-12 mb-5'><article class='card shadow'><div class='card-body'>"
    $newBlog += "<h2 class='card-title mb-3'>$($post.Title)</h2>"
    $newBlog += "<div class='mb-3 text-muted'><small>Date: $($post.Date)</small></div>"
    $newBlog += "<div class='blog-content'><p>$($post.Excerpt)</p></div>"
    $newBlog += "<div class='mt-3'><a href='$($post.Url)' target='_blank' class='btn btn-primary'>Read More &rarr;</a></div>"
    $newBlog += "</div></article></div>"
}

$newBlog += "</div><!-- Back to Home Button --><div class='row mt-4'><div class='col-12 text-center'><a href='index.html' class='btn btn-outline-primary'>Back to Home</a></div></div></div></section>"
$newBlog += $footer

$newBlog | Out-File -FilePath $mainHtml -Encoding UTF8
Write-Host "Done! Created $($allPosts.Count) post pages and updated blog.html"
