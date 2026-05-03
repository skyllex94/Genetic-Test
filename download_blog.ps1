# Script to download all blog posts and images from bliznaci.blog.bg
# Save this script and run it in PowerShell

$baseUrl = "https://bliznaci.blog.bg"
$outputDir = "D:\GenTest\Genetic-Test"
$blogDir = "$outputDir\blog"
$imgDir = "$outputDir\img\blog"
$postsFile = "$blogDir\posts.txt"

# Create directories
New-Item -ItemType Directory -Path $blogDir -Force | Out-Null
New-Item -ItemType Directory -Path $imgDir -Force | Out-Null

# Array to store post URLs
$postUrls = @()

# Fetch listing pages 1-6
for ($page = 1; $page -le 6; $page++) {
    if ($page -eq 1) {
        $url = "$baseUrl/"
    } else {
        $url = "$baseUrl/?&page=$page"
    }
    Write-Host "Fetching listing page $page : $url"
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing
        # Extract links to posts: pattern /drugi/YYYY/MM/dd/slug.ID
        $links = $response.Links | Where-Object { $_.href -match '/drugi/\d{4}/\d{2}/\d{2}/[a-z0-9\-\.]+\.\d+$' }
        foreach ($link in $links) {
            $absoluteUrl = $link.href
            if ($absoluteUrl -notmatch '^https?://') {
                $absoluteUrl = $baseUrl + $absoluteUrl
            }
            if ($postUrls -notcontains $absoluteUrl) {
                $postUrls += $absoluteUrl
            }
        }
    } catch {
        Write-Warning "Failed to fetch $url : $_"
    }
}

# Save post URLs
$postUrls | Out-File -FilePath $postsFile -Encoding UTF8
Write-Host "Found $($postUrls.Count) posts. URLs saved to $postsFile"

# Download each post
foreach ($postUrl in $postUrls) {
    Write-Host "Processing $postUrl"
    try {
        $postResponse = Invoke-WebRequest -Uri $postUrl -UseBasicParsing
        # Extract post ID from URL
        if ($postUrl -match '\.(\d+)$') {
            $postId = $matches[1]
        } else {
            $postId = [System.IO.Path]::GetRandomFileName()
        }
        $postFile = "$blogDir\post_$postId.html"
        # Save the HTML content
        $postResponse.Content | Out-File -FilePath $postFile -Encoding UTF8
        Write-Host "Saved post to $postFile"
        # Extract image URLs from the page
        $images = $postResponse.Images | Where-Object { $_.src -match '/photos/173622/' }
        foreach ($img in $images) {
            $imgSrc = $img.src
            if ($imgSrc -match '^/') {
                $imgUrl = $baseUrl + $imgSrc
            } else {
                $imgUrl = $imgSrc
            }
            $imgFileName = [System.IO.Path]::GetFileName($imgSrc)
            $imgOutPath = "$imgDir\$imgFileName"
            try {
                Invoke-WebRequest -Uri $imgUrl -OutFile $imgOutPath
                Write-Host "Downloaded image: $imgFileName"
            } catch {
                Write-Warning "Failed to download image $imgUrl : $_"
            }
        }
    } catch {
        Write-Warning "Failed to process $postUrl : $_"
    }
}

Write-Host "Download complete."
