# Check all lesson folders for image sizes
$lessonPath = "e:\Apps\gravity_app\assets\Lessons"
$results = @()

Get-ChildItem -Path $lessonPath -Directory | ForEach-Object {
    $lessonName = $_.Name
    $images = Get-ChildItem -Path $_.FullName -File -Filter "*.webp"
    
    foreach ($img in $images) {
        $sizeKB = [math]::Round($img.Length / 1KB, 2)
        $results += [PSCustomObject]@{
            Lesson = $lessonName
            Image = $img.Name
            SizeKB = $sizeKB
            Status = if ($sizeKB -lt 50) { "2D (Small)" } else { "3D (Large)" }
        }
    }
}

# Group by lesson and show summary
Write-Host "`n=== LESSON IMAGE ANALYSIS ===" -ForegroundColor Green
Write-Host "Threshold: <50KB = 2D flat, >=50KB = 3D Pixar`n" -ForegroundColor Yellow

$results | Group-Object Lesson | ForEach-Object {
    $lessonName = $_.Name
    $images = $_.Group
    $small = ($images | Where-Object { $_.SizeKB -lt 50 }).Count
    $large = ($images | Where-Object { $_.SizeKB -ge 50 }).Count
    $total = $images.Count
    
    if ($small -gt 0) {
        Write-Host "`n$lessonName" -ForegroundColor Cyan
        Write-Host "  Total: $total images | 2D: $small | 3D: $large" -ForegroundColor $(if ($small -gt 0) { "Red" } else { "Green" })
        
        # Show small images
        $images | Where-Object { $_.SizeKB -lt 50 } | ForEach-Object {
            Write-Host "    ❌ $($_.Image) - $($_.SizeKB) KB" -ForegroundColor Red
        }
    }
}

# Export full results
$results | Export-Csv -Path "e:\Apps\gravity_app\image_size_audit.csv" -NoTypeInformation
Write-Host "`n✅ Full audit saved to: image_size_audit.csv" -ForegroundColor Green
