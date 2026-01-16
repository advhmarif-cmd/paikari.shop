$src = "C:\Users\advhm\.gemini\antigravity\brain\3959f8d8-a897-4ed4-8d4a-549b2ccf240d\uploaded_image_1766898263084.jpg"
$dst = "c:\Users\advhm\paikari.shop\assets\logo.jpg"
Write-Output "Copying..." | Out-File -FilePath output.log -Encoding utf8
try {
    Copy-Item -Path $src -Destination $dst -Force -ErrorAction Stop
    Write-Output "Success" | Out-File -FilePath output.log -Append -Encoding utf8
    Get-Item $dst | Out-File -FilePath output.log -Append -Encoding utf8
} catch {
    Write-Output "Failed: $_" | Out-File -FilePath output.log -Append -Encoding utf8
}
