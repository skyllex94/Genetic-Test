# Script to clean up blog images
$imgDir = "D:\GenTest\Genetic-Test\img\blog"
$blogHtmlPath = "D:\GenTest\Genetic-Test\blog.html"

# Step 1: Decode all URL-encoded filenames in img/blog/
Write-Host "Step 1: Decoding URL-encoded filenames..."
Get-ChildItem $imgDir -File | ForEach-Object {
    $oldPath = $_.FullName
    $oldName = $_.Name
    try {
        $decodedName = [System.Uri]::UnescapeDataString($oldName)
        if ($decodedName -ne $oldName -and $decodedName -match '\.[a-z]{3,4}$') {
            $newPath = Join-Path $imgDir $decodedName
            if (-not (Test-Path $newPath)) {
                Rename-Item $oldPath -NewName $decodedName
                Write-Host "  Decoded: $oldName -> $decodedName"
            }
        }
    } catch { }
}

# Step 2: Update blog.html to use decoded filenames
Write-Host "Step 2: Updating blog.html with decoded image names..."
$html = Get-Content $blogHtmlPath -Raw
Get-ChildItem $imgDir -File | ForEach-Object {
    $fileName = $_.Name
    $encoded = [System.Uri]::EscapeDataString($fileName)
    if ($encoded -ne $fileName) {
        $html = $html.Replace("/img/blog/$encoded", "/img/blog/$fileName")
    }
}
$html | Out-File -FilePath $blogHtmlPath -Encoding UTF8

# Step 3: Find which images are actually referenced in blog.html
Write-Host "Step 3: Finding referenced images..."
$html = Get-Content $blogHtmlPath -Raw
$referenced = [System.Collections.Generic.HashSet[string]]::new()
[regex]::Matches($html, '/img/blog/([^"\s<>]+)') | ForEach-Object {
    [void]$referenced.Add($_.Groups[1].Value)
}
Write-Host "  Referenced images: $($referenced.Count)"

# Step 4: Remove images not referenced in blog.html
Write-Host "Step 4: Removing unreferenced images..."
Get-ChildItem $imgDir -File | ForEach-Object {
    if ($_.Name -notin $referenced) {
        Write-Host "  Deleting unreferenced: $($_.Name)"
        Remove-Item $_.FullName -Force
    }
}

# Step 5: Remove duplicates by content hash
Write-Host "Step 5: Removing duplicate images by content..."
$files = Get-ChildItem $imgDir -File
$hashTable = @{}
$duplicates = @()
foreach ($file in $files) {
    $hash = Get-FileHash $file.FullName -Algorithm MD5
    if ($hashTable.ContainsKey($hash.Hash)) {
        $duplicates += $file.Name
        Write-Host "  Duplicate: $($file.Name) matches $($hashTable[$hash.Hash])"
    } else {
        $hashTable[$hash.Hash] = $file.Name
    }
}
foreach ($dup in $duplicates) {
    $dupPath = Join-Path $imgDir $dup
    Remove-Item $dupPath -Force
    Write-Host "  Deleted duplicate: $dup"
}

Write-Host "Done! Final image count:"
Get-ChildItem $imgDir | Measure-Object
Get-ChildItem $imgDir | Format-Table Name, @{Name="SizeKB";Expression={[math]::Round($_.Length/1KB,2)}} -AutoSize
