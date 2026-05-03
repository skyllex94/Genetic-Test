# Script to process all blog posts and update blog.html
$blogDir = "D:\GenTest\Genetic-Test\blog"
$imgBlogDir = "D:\GenTest\Genetic-Test\img\blog"
$outputFile = "D:\GenTest\Genetic-Test\blog.html"
$posts = @()

# Read all post HTML files
$postFiles = Get-ChildItem -Path $blogDir -Filter "post_*.html" | Sort-Object Name

foreach ($file in $postFiles) {
    # Extract post ID from filename
    if ($file.Name -match 'post_(\d+)\.html') {
        $postId = $matches[1]
    } else {
        continue
    }

    # Read HTML content with correct encoding (windows-1251)
    $htmlBytes = Get-Content -Path $file.FullName -Encoding Byte
    $html = [System.Text.Encoding]::GetEncoding("windows-1251").GetString($htmlBytes)

    # Extract title (from <title> tag, remove site name)
    $titleMatch = [regex]::Match($html, '<title>([^<]+) ::')
    $title = if ($titleMatch.Success) { $titleMatch.Groups[1].Value.Trim() } else { "Без заглавие" }

    # Extract publication date
    $dateMatch = [regex]::Match($html, '(\d{2}\.\d{2} \d{2}:\d{2}) -')
    $date = if ($dateMatch.Success) { $dateMatch.Groups[1].Value } else { "" }

    # Extract images (local paths)
    $imageMatches = [regex]::Matches($html, 'src="(/photos/173622/[^"]+)"')
    $localImages = @()
    foreach ($imgMatch in $imageMatches) {
        $imgSrc = $imgMatch.Groups[1].Value
        $imgFileName = [System.IO.Path]::GetFileName($imgSrc)
        $localImages += "/img/blog/$imgFileName"
    }

    # Extract post content (simplified: get text between date and comments)
    # Look for content after the date line, before comments section
    $contentStart = $html.IndexOf($date)
    if ($contentStart -gt 0) {
        $contentStart = $html.IndexOf("<", $contentStart)
        # Find the main content area (look for <p> tags or <div> with post content)
        $contentEnd = $html.IndexOf("Коментари", $contentStart)
        if ($contentEnd -lt 0) { $contentEnd = $html.IndexOf("comments", $contentStart) }
        if ($contentEnd -lt 0) { $contentEnd = $html.Length - 1 }
        
        $contentHtml = $html.Substring($contentStart, $contentEnd - $contentStart)
        # Remove blog.bg specific tags and scripts
        $contentHtml = [regex]::Replace($contentHtml, '<script[^>]*>.*?</script>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $contentHtml = [regex]::Replace($contentHtml, '<style[^>]*>.*?</style>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $contentHtml = [regex]::Replace($contentHtml, '<div[^>]*id="(ado|fb|twitter)[^"]*"[^>]*>.*?</div>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        # Replace image paths with local paths
        foreach ($imgMatch in $imageMatches) {
            $oldSrc = $imgMatch.Groups[1].Value
            $imgFileName = [System.IO.Path]::GetFileName($oldSrc)
            $contentHtml = $contentHtml.Replace($oldSrc, "/img/blog/$imgFileName")
        }
    } else {
        $contentHtml = "<p>Съдържанието ще бъде добавено скоро.</p>"
    }

    # Create post object
    $post = [PSCustomObject]@{
        Id = $postId
        Title = $title
        Date = $date
        Images = $localImages
        Content = $contentHtml
    }
    $posts += $post
    Write-Host "Processed: $title ($postId)"
}

# Now generate the blog.html content
# First read the existing blog.html to preserve header/footer
$existingHtml = Get-Content -Path $outputFile -Encoding UTF8 -Raw

# Find the section where posts are inserted (between "<!-- Blog Posts -->" and "<!-- Back to Home Button -->")
$postsStartMarker = "<!-- Blog Posts -->"
$postsEndMarker = "<!-- Back to Home Button -->"

$postsStartIndex = $existingHtml.IndexOf($postsStartMarker)
$postsEndIndex = $existingHtml.IndexOf($postsEndMarker)

if ($postsStartIndex -gt 0 -and $postsEndIndex -gt 0) {
    # Build new posts HTML
    $newPostsHtml = "$postsStartMarker`n            <div class=`"row`">`n"
    
    $postCount = 0
    foreach ($post in $posts) {
        $postCount++
        $postHtml = @"
                <!-- Blog Post $postCount -->
                <div class="col-12 mb-5">
                    <article class="card shadow">
"@
        # Add first image if available
        if ($post.Images.Count -gt 0) {
            $imgSrc = $post.Images[0]
            $postHtml += @"
                        <img src="$imgSrc" class="card-img-top mx-auto d-block" alt="$($post.Title)" style="height: 400px; object-fit: contain; width: 100%;">
"@
        }
        $postHtml += @"
                        <div class="card-body">
                            <h2 class="card-title mb-3">$($post.Title)</h2>
                            <div class="mb-3 text-muted">
                                <small>Публикувано на: $($post.Date)</small>
                            </div>

                            <div class="blog-content">
                                $($post.Content)
                            </div>
                        </div>
                    </article>
                </div>
"@
        $newPostsHtml += $postHtml
    }
    
    $newPostsHtml += "            </div>`n$postsEndMarker"
    
    # Replace the old posts section with new one
    $beforePosts = $existingHtml.Substring(0, $postsStartIndex)
    $afterPosts = $existingHtml.Substring($postsEndIndex)
    
    $newHtml = $beforePosts + $newPostsHtml + $afterPosts
    
    # Write the updated HTML
    $newHtml | Out-File -FilePath $outputFile -Encoding UTF8
    Write-Host "Updated $outputFile with $postCount posts."
} else {
    Write-Warning "Could not find post markers in blog.html"
}
