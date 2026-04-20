# PowerShell Profile

# Remove built-in aliases so Scoop-installed binaries take precedence
Remove-Item Alias:curl -ErrorAction SilentlyContinue
Remove-Item Alias:wget -ErrorAction SilentlyContinue

# Force curl to use Scoop version since System32\curl.exe takes PATH precedence
Set-Alias curl "$env:USERPROFILE\scoop\shims\curl.exe"
