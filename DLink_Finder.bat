<# ::

    @echo off & echo. & title DLink Finder & setlocal
    
    if /i "%~1"=="/?"     goto :help
    if /i "%~1"=="-?"     goto :help
    if /i "%~1"=="--?"    goto :help
    if /i "%~1"=="/help"  goto :help
    if /i "%~1"=="-help"  goto :help
    if /i "%~1"=="--help" goto :help

    set "f0=%~f0" & set "n0=%~n0"
    set "name="  
    set "url="   
    set "pattern="
    set "extension="
    :parse_args
    if "%~1"=="" goto :after_args
    if /i "%~1"=="/name"      (set "name=%~2"      & shift & shift & goto :parse_args)
    if /i "%~1"=="/url"       (set "url=%~2"       & shift & shift & goto :parse_args)
    if /i "%~1"=="/pattern"   (set "pattern=%~2"   & shift & shift & goto :parse_args)
    if /i "%~1"=="/extension" (set "extension=%~2" & shift & shift & goto :parse_args)
    if /i "%~1"=="/lucky"    (set "lucky=1"      & shift & shift & goto :parse_args)
    if /i "%~1"=="/exclude"  (set "exclude=%~2"  & shift & shift & goto :parse_args)    
    REM We hit this point if an argument is not recognized
    echo Argument not recognized : "%~1"
    pause & exit /b 2
    :after_args

    powershell  -Command "Get-Content '%f0%' -Encoding UTF8 | Set-Content '%TEMP%\%n0%.ps1' -Encoding UTF8"
    powershell  -Nologo -NoProfile -ExecutionPolicy Bypass -File "%TEMP%\%n0%.ps1" ^
                -name "%name%" -url "%url%" -pattern "%pattern%" -extension "%extension%"
                
    set returncode=%ERRORLEVEL%
    exit /b %returncode%

    :help
    echo.
    echo    =============================================================================
    echo                                 DLink Finder v1.3                              
    echo                        Download Files From Web Pages Easily
    echo    =============================================================================
    echo.   
    echo    DESCRIPTION:
    echo       Automatically finds and downloads files from web pages, GitHub repositories,
    echo       and release pages. Supports multiple file types and filtering options.
    echo.   
    echo    SYNTAX:
    echo       %~n0 [/name name] [/url url] [/pattern pattern] [/extension ext] 
    echo           [/lucky] [/exclude pattern]
    echo.   
    echo    PARAMETERS:
    echo       Required:
    echo       -----------
    echo       /url         URL of the webpage to analyze
    echo.   
    echo       Optional:
    echo       -----------
    echo       /name        Custom name for console output and messages
    echo       /pattern     Text pattern to filter download links (e.g., "x64", "win64")
    echo       /extension   Specific file extension to search for (e.g., exe, msi, zip)
    echo       /lucky       Automatically select and download the first matching file
    echo       /exclude     Pattern to exclude from search results (e.g., "beta", "test")
    echo.   
    echo    EXAMPLES:
    echo       Basic usage:
    echo       -----------
    echo       %~n0 /url https://example.com /extension exe
    echo       - Finds all .exe files on the specified webpage
    echo.   
    echo       Filtered search:
    echo       -----------
    echo       %~n0 /url https://example.com /pattern "64bit" /extension msi /exclude "beta"
    echo       - Finds 64-bit MSI files, excluding beta versions
    echo.   
    echo       Quick download:
    echo       -----------
    echo       %~n0 /url https://github.com/user/repo/releases /extension zip /lucky
    echo       - Automatically downloads the first ZIP file found
    echo.   
    echo       Named search:
    echo       -----------
    echo       %~n0 /name "Visual Studio Code" /url https://code.visualstudio.com /pattern "system"
    echo       - Searches with custom name for system installer
    echo.   
    echo    NOTES:
    echo       * Without /extension specified, searches for all common file types
    echo       * /lucky is useful for automated scripts and known download pages
    echo       * /pattern and /exclude support partial matches and are case-insensitive
    echo       * Special support for GitHub repositories and release pages
    echo       * Downloads are saved to the current directory
    echo.   
    echo    SUPPORTED SITES:
    echo       * Generic websites
    echo       * GitHub repositories
    echo       * GitHub release pages
    echo       * Direct download links
    echo.   
    echo    =============================================================================
    echo.
    exit /b 0

#>

#===========================================================#
#                    DLink Finder v1.3                      #
#                           ---                             #
#                      Author : FNTL                        #
#===========================================================#


param(
    [string]$name,
    [string]$url,
    [string]$pattern,
    [string]$extension,
    [int]$lucky,
    [string]$exclude
)

Add-Type -AssemblyName System.Web



#          ____________________________________________________________          #
#      ____________________________________________________________________      #
#  ____________________________________________________________________________  #

# ------------------------------------------------------------------------------ #
# COMPLETE VARIABLES BELOW IF YOU DON'T WANT TO CALL THIS SCRIPT WITH ARGUMENTS. #
#             PATTERN = OPTIONAL, SEARCH TEXT INSIDE FOUND LINKS                 #
# ------------------------------------------------------------------------------ #

$default_name = ""        # Only for console output (can be empty)
$default_url = ""         # URL to parse
$default_pattern = ""     # Pattern to search in filenames, eg: 64 (can be empty)
$default_extension = ""   # File extension to search for
$default_lucky = 0
$default_exclude = ""

# ------------------------------------------------------------------------------ #
#                         YOU CAN STOP READ FROM THERE                           #
# ------------------------------------------------------------------------------ #
#  ____________________________________________________________________________  #
#      ____________________________________________________________________      #
#          ____________________________________________________________          #




# Use default values if parameters are not provided
$name = if ($name) { $name } else { $default_name }
$url = if ($url) { $url } else { $default_url }
$pattern = if ($pattern) { $pattern } else { $default_pattern }
$extension = if ($extension) { $extension } else { $default_extension }
$lucky = if ($lucky -eq 1) { 1 } else { $default_lucky }
$exclude = if ($exclude) { $exclude } else { $default_exclude }

Write-Host "URL = $url"

#===========================================================#
#                   Helper Functions                        #
#===========================================================#

$downloadPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Function to get a single keypress
function Get-KeyPress {
    $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    return [int]$key.Character.ToString()
}

$extensionsToSearch = if ($extension) { 
    @($extension) 
} else { 
    @(
        # Executables and Installers
        'exe', 'msi', 'msix', 'msp', 'appx', 'appxbundle', 'bat', 'cmd', 'ps1', 'vbs', 'reg',

        # Compressed Archives
        'zip', 'rar', '7z', 'gz', 'tar', 'tgz', 'bz2', 'xz', 'cab', 'iso', 'img',

        # Development
        'dll', 'lib', 'sys', 'ocx', 'jar', 'war', 'ear', 'class', 'pyc', 'pyd',
        'so', 'dylib', 'framework', 'bundle', 'app',

        # Documents and Data
        'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'csv', 'xml', 'json',
        'yaml', 'yml', 'ini', 'conf', 'config', 'txt', 'md', 'rst', 'rtf',

        # Web and Scripts
        'html', 'htm', 'php', 'asp', 'aspx', 'jsp', 'js', 'css', 'less', 'sass',
        'scss', 'vue', 'jsx', 'tsx', 'ts', 'coffee',

        # Programming Languages
        'c', 'cpp', 'h', 'hpp', 'cs', 'vb', 'java', 'py', 'rb', 'pl', 'php',
        'swift', 'go', 'rs', 'r', 'm', 'mm', 'f', 'f90', 'kt', 'kts',

        # Media
        'mp3', 'wav', 'ogg', 'flac', 'wma', 'aac', 'm4a',
        'mp4', 'avi', 'mkv', 'mov', 'wmv', 'flv', 'webm',
        'jpg', 'jpeg', 'png', 'gif', 'bmp', 'tiff', 'svg', 'webp',

        # Database
        'db', 'sqlite', 'sqlite3', 'mdb', 'accdb', 'sql', 'bak',

        # Design and Graphics
        'psd', 'ai', 'eps', 'indd', 'raw', 'sketch', 'fig',
        'xcf', 'cdr', 'blend', 'fbx', 'obj', '3ds', 'max',

        # Configuration and Project Files
        'properties', 'env', 'cfg', 'toml', 'lock', 'gradle',
        'pom', 'sln', 'csproj', 'vbproj', 'vcxproj', 'pbxproj',

        # Container and VM
        'dockerfile', 'vagrantfile', 'dockerignore', 'ova', 'ovf', 'vdi', 'vmdk',

        # Font Files
        'ttf', 'otf', 'woff', 'woff2', 'eot',

        # Package Files
        'deb', 'rpm', 'pkg', 'dmg', 'apk', 'ipa',

        # Security and Certificates
        'key', 'pem', 'cer', 'crt', 'csr', 'p12', 'pfx',

        # Game Development
        'unity', 'unitypackage', 'asset', 'map', 'bsp', 'pak', 'uasset',

        # Misc
        'log', 'dat', 'bin', 'hex', 'patch', 'diff', 'sum', 'sig',
        'torrent', 'part', 'crdownload', 'temp'
    )
}

function Get-SiteType {
    param ([string]$Url)
    
    $patterns = [ordered]@{
        'GitHubRelease' = '^https?://(?:www\.)?github\.com/([^/]+)/([^/]+)/releases(?:/tag/([^/]+)|/latest|/?$)'
        'GitHubRepo' = '^https?://(?:www\.)?github\.com/([^/]+)/([^/]+)(?:/(?!releases).*)?$'
    }
    
    foreach ($site in $patterns.Keys) {
        if ($Url -match $patterns[$site]) {
            Write-Host "[DEBUG] Matched pattern: $site" -ForegroundColor Gray
            
            if ($site -eq 'GitHubRepo') {
                $script:repoOwner = $matches[1]
                $script:repoName = $matches[2]
            } elseif ($site -eq 'GitHubRelease') {
                $script:repoOwner = $matches[1]
                $script:repoName = $matches[2]
                $script:releaseTag = if ($matches.Count -gt 3) { $matches[3] } else { "" }
                Write-Host "[DEBUG] Release info - Owner: $repoOwner, Repo: $repoName, Tag: $releaseTag" -ForegroundColor Gray
            }
            return $site
        }
    }
    return 'Generic'
}

function Get-GitHubReleaseAssetLinks {
    param ([string]$Owner, [string]$Repo, [string]$Tag)
    
    try {
        $links = @()
        
        $isAllReleases = $Tag -eq "" -and $url -match "/releases$"
        
        if ($isAllReleases) {
            $apiUrl = "https://api.github.com/repos/$Owner/$Repo/releases"
            Write-Host "[INFO] Accessing GitHub API for all releases: $apiUrl" -ForegroundColor Cyan
            
            $headers = @{
                'Accept' = 'application/vnd.github.v3+json'
            }
            
            $releases = Invoke-RestMethod -Uri $apiUrl -Headers $headers -UseBasicParsing
            
            foreach ($release in $releases) {
                foreach ($asset in $release.assets) {
                    if ([string]::IsNullOrEmpty($extension) -or $asset.name -match "\.$extension($|\?)") {
                        $links += [PSCustomObject]@{
                            Url = $asset.browser_download_url
                            ReleaseName = $release.name
                            ReleaseTag = $release.tag_name
                            PublishedAt = [DateTime]::Parse($release.published_at)
                        }
                    }
                }
            }
        } else {
            $apiUrl = if ([string]::IsNullOrEmpty($Tag) -or $Tag -eq "latest") {
                "https://api.github.com/repos/$Owner/$Repo/releases/latest"
            } else {
                "https://api.github.com/repos/$Owner/$Repo/releases/tags/$Tag"
            }
            
            Write-Host "[INFO] Accessing GitHub API for specific release: $apiUrl" -ForegroundColor Cyan
            
            $headers = @{
                'Accept' = 'application/vnd.github.v3+json'
            }
            
            $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers -UseBasicParsing
            
            foreach ($asset in $release.assets) {
                if ([string]::IsNullOrEmpty($extension) -or $asset.name -match "\.$extension($|\?)") {
                    $links += [PSCustomObject]@{
                        Url = $asset.browser_download_url
                        ReleaseName = $release.name
                        ReleaseTag = $release.tag_name
                        PublishedAt = [DateTime]::Parse($release.published_at)
                    }
                }
            }
        }

        if ($exclude) {
            $beforeCount = $links.Count
            $links = $links | Where-Object { $_.Url -notmatch $exclude }
            $excludedCount = $beforeCount - $links.Count
            if ($excludedCount -gt 0) {
                Write-Host "[INFO] Excluded $excludedCount files matching '$exclude'" -ForegroundColor Yellow
            }
        }

        if ($links.Count -gt 0) {
            $extensionIndex = @{}
            for ($i = 0; $i -lt $extensionsToSearch.Count; $i++) {
                $extensionIndex[$extensionsToSearch[$i]] = $i
            }

            $sortedLinks = $links | Sort-Object {
                $_.PublishedAt
            } -Descending | Group-Object {
                if ($_.Url -match '\.([^.\?]+)(?:\?|$)') { 
                    $matches[1].ToLower()
                } else { 
                    'unknown'
                }
            } | Sort-Object {
                $ext = $_.Name
                if ($extensionIndex.ContainsKey($ext)) {
                    $extensionIndex[$ext]
                } else {
                    [int]::MaxValue
                }
            } | ForEach-Object { $_.Group } | Select-Object -ExpandProperty Url

            Write-Host "[SUCCESS] Found $($sortedLinks.Count) assets" -ForegroundColor Green
            if ($isAllReleases) {
                $releaseCount = ($links | Select-Object -ExpandProperty ReleaseTag -Unique).Count
                Write-Host "[INFO] From $releaseCount different releases" -ForegroundColor Cyan
            }

            $groupedByExt = $sortedLinks | Group-Object { 
                if ($_ -match '\.([^.\?]+)(?:\?|$)') { $matches[1] } else { 'unknown' }
            }
            foreach ($group in $groupedByExt) {
                Write-Host "  - .$($group.Name): $($group.Count) files" -ForegroundColor Cyan
            }

            return $sortedLinks
        }
        
        Write-Host "[WARNING] No matching assets found" -ForegroundColor Yellow
        return @()
        
    } catch {
        Write-Host "[ERROR] Could not retrieve release assets: $_" -ForegroundColor Red
        return @()
    }
}

function Get-GitHubRepoLinks {
    param ([string]$Owner, [string]$Repo)
    
    try {
        $links = [System.Collections.ArrayList]::new()
        $headers = @{
            'Accept' = 'application/vnd.github.v3+json'
            'User-Agent' = 'PowerShell Release Finder'
        }

        Write-Host "[INFO] Searching GitHub repository for downloadable files..." -ForegroundColor Cyan

        try {
            $branch = "main"
            $contentsUrl = "https://api.github.com/repos/$Owner/$Repo/contents"
            try {
                $contents = Invoke-RestMethod -Uri $contentsUrl -Headers $headers -UseBasicParsing
            } catch {
                $branch = "master"
                $contentsUrl = "https://api.github.com/repos/$Owner/$Repo/contents"
                $contents = Invoke-RestMethod -Uri $contentsUrl -Headers $headers -UseBasicParsing
            }

            $extensionPattern = if ($extension) { "\.$extension$" } else { "\.[^\.]+$" }

            foreach ($item in $contents) {
                if ($item.type -eq "file" -and $item.name -match $extensionPattern) {
                    if ($exclude -and ($item.name -match $exclude -or $item.download_url -match $exclude)) {
                        continue
                    }
                    [void]$links.Add($item.download_url)

                    if ($links.Count -ge 1000) {
                        Write-Host "[INFO] Reached maximum number of files (1000)" -ForegroundColor Cyan
                        break
                    }
                }
            }
        }
        catch {
            Write-Host "[DEBUG] Error accessing repository contents: $_" -ForegroundColor Gray
        }

        $sortedLinks = [System.Collections.ArrayList]::new()
        
        $extensionIndex = @{}
        for ($i = 0; $i -lt $extensionsToSearch.Count; $i++) {
            $extensionIndex[$extensionsToSearch[$i]] = $i
        }

        $groupedLinks = $links | Group-Object {
            if ($_ -match '\.([^.\?]+)(?:\?|$)') { 
                $matches[1].ToLower()
            } else { 
                'unknown'
            }
        }

        $sortedGroups = $groupedLinks | Sort-Object {
            $ext = $_.Name
            if ($extensionIndex.ContainsKey($ext)) {
                $extensionIndex[$ext]
            } else {
                [int]::MaxValue
            }
        }

        foreach ($group in $sortedGroups) {
            $sortedLinks.AddRange($group.Group)
        }

        if ($sortedLinks.Count -gt 0) {
            Write-Host "[SUCCESS] Found $($sortedLinks.Count) matching files" -ForegroundColor Green
            
            if (-not $extension) {
                $foundExtensions = $sortedLinks | ForEach-Object {
                    if ($_ -match '\.([^.]+)$') { $matches[1] }
                } | Select-Object -Unique
                Write-Host "[INFO] Found files with extensions: $($foundExtensions -join ', ')" -ForegroundColor Cyan
            }
        }

        return $sortedLinks

    } catch {
        Write-Host "[WARNING] GitHub repository access error: $_" -ForegroundColor Yellow
        return @()
    }
}

function Get-DynamicContent {
    param (
        [string]$Url,
        [Microsoft.PowerShell.Commands.BasicHtmlWebResponseObject]$InitialResponse
    )
    
    $links = @()
    
    try {
        # Simulate browser fingerprint
        $headers = @{
            'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            'Accept' = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
            'Accept-Language' = 'en-US,en;q=0.5'
        }

        if ($null -eq $InitialResponse) {
            Write-Host "[INFO] Retrying with browser headers..." -ForegroundColor Yellow
            $InitialResponse = Invoke-WebRequest -Uri $Url -Headers $headers -UseBasicParsing
        }

        $extensionsToUse = if ($extension) { @($extension) } else { $extensionsToSearch }

        foreach ($ext in $extensionsToUse) {
            if ($InitialResponse.Links) {
                $links += @($InitialResponse.Links | Where-Object { 
                    $_.href -and ($_.href -match "\.$ext($|\?)") -and ($_.href -match '^https?://')
                } | Select-Object -ExpandProperty href)
            }

            $extPattern = '\.' + [Regex]::Escape($ext) + '(?:\?[^''`"\s]*)?'
            
            $patterns = @(
                'https?://[^''`"\s]+?' + $extPattern,
                'href=["'']?(https?://[^''`"\s]+?' + $extPattern + ')["'']?',
                'data-url=["'']?(https?://[^''`"\s]+?' + $extPattern + ')["'']?'
            )

            foreach ($pattern in $patterns) {
                if ($InitialResponse.Content) {
                    $patternMatches = [regex]::Matches($InitialResponse.Content, $pattern)
                    $links += @($patternMatches | ForEach-Object { 
                        if ($_.Groups.Count -gt 1) { $_.Groups[1].Value } else { $_.Value }
                    })
                }
            }
        }

        $validLinks = @()
        foreach ($link in $links) {
            if ($link -match '^https?://') {
                $isValidExtension = if ($extension) {
                    $link -match "\.$extension($|\?)"
                } else {
                    $extensionsToSearch | Where-Object { $link -match "\.$_($|\?)" }
                }

                if ($isValidExtension) {
                    try {
                        $uri = [System.Uri]::new($link)
                        if ($uri.Scheme -match '^https?$') {
                            $validLinks += $uri.AbsoluteUri
                        }
                    } catch {
                        Write-Host "[WARNING] Invalid URL found: $link" -ForegroundColor Yellow
                    }
                }
            }
        }

        $validLinks = $validLinks | Select-Object -Unique

        if ($exclude) {
            $beforeCount = $validLinks.Count
            $validLinks = $validLinks | Where-Object { $_ -notmatch $exclude }
            $excludedCount = $beforeCount - $validLinks.Count
            if ($excludedCount -gt 0) {
                Write-Host "[INFO] Excluded $excludedCount files matching '$exclude'" -ForegroundColor Yellow
            }
        }

        if ($validLinks.Count -gt 0) {
            $extensionIndex = @{}
            for ($i = 0; $i -lt $extensionsToSearch.Count; $i++) {
                $extensionIndex[$extensionsToSearch[$i]] = $i
            }

            $sortedLinks = $validLinks | Group-Object {
                if ($_ -match '\.([^.\?]+)(?:\?|$)') { 
                    $matches[1].ToLower()
                } else { 
                    'unknown'
                }
            } | Sort-Object {
                $ext = $_.Name
                if ($extensionIndex.ContainsKey($ext)) {
                    $extensionIndex[$ext]
                } else {
                    [int]::MaxValue
                }
            } | ForEach-Object { $_.Group }

            Write-Host "[INFO] Found $($sortedLinks.Count) valid download links:" -ForegroundColor Cyan
            
            $groupedLinks = $sortedLinks | Group-Object { 
                if ($_ -match '\.([^.\?]+)(?:\?|$)') { $matches[1] } else { 'unknown' }
            }
            foreach ($group in $groupedLinks) {
                Write-Host "  - .$($group.Name): $($group.Count) files" -ForegroundColor Cyan
            }

            return $sortedLinks
        }

        Write-Host "[WARNING] No valid download links found" -ForegroundColor Yellow
        return @()

    } catch {
        Write-Host "[ERROR] Error in Get-DynamicContent: $_" -ForegroundColor Red
        return @()
    }
}

function Invoke-ApplicationInstallation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ExeLink,
        [Parameter(Mandatory = $true)]
        [string]$DownloadPath
    )

    try {
        Write-Host "`n[INFO] Downloading file..." -ForegroundColor Cyan
        
        # Extract file name
        $fileName = try {
            $uri = [System.Uri]$ExeLink
            $lastSegment = $uri.Segments[-1]
            if ([string]::IsNullOrWhiteSpace($lastSegment) -or $lastSegment -eq "/" -or $lastSegment.Length -le 4) {
                "download_$(Get-Date -Format 'yyyyMMddHHmmss').$extension"
            } else {
                [System.Web.HttpUtility]::UrlDecode($lastSegment)
            }
        } catch {
            "download_$(Get-Date -Format 'yyyyMMddHHmmss').$extension"
        }

        $filePath = Join-Path $DownloadPath $fileName
        Write-Host "[INFO] Downloading to: $filePath" -ForegroundColor Cyan

        function Write-ProgressBar {
            param(
                [int]$percent,
                [double]$downloadedMB,
                [double]$totalMB,
                [double]$speed
            )
            $width = 50
            $filled = [math]::Round($width * $percent / 100)
            $empty = $width - $filled
            $bar = "[" + ("=" * $filled) + (" " * $empty) + "]"
            
            Write-Host "`r" + (" " * 80) + "`r" -NoNewline
            
            $message = "{0} {1}% {2:N1}MB/{3:N1}MB ({4:N1} MB/s)" -f $bar, $percent, $downloadedMB, $totalMB, $speed
            Write-Host $message -NoNewline -ForegroundColor Cyan
        }

        try {
            $webRequest = [System.Net.HttpWebRequest]::Create($ExeLink)
            $webRequest.Method = "HEAD"
            $webRequest.UserAgent = "Mozilla/5.0"
            $response = $webRequest.GetResponse()
            $totalBytes = $response.ContentLength
            $response.Close()

            $fileStream = [System.IO.File]::Create($filePath)
            
            $webRequest = [System.Net.HttpWebRequest]::Create($ExeLink)
            $webRequest.UserAgent = "Mozilla/5.0"
            $response = $webRequest.GetResponse()
            $responseStream = $response.GetResponseStream()
            
            $buffer = New-Object byte[] 10KB
            $totalBytesRead = 0
            $timer = [System.Diagnostics.Stopwatch]::StartNew()
            $lastUpdate = 0
            $lastBytesRead = 0

            while ($true) {
                $bytesRead = $responseStream.Read($buffer, 0, $buffer.Length)
                if ($bytesRead -eq 0) { break }
                
                $fileStream.Write($buffer, 0, $bytesRead)
                $totalBytesRead += $bytesRead
                
                $now = $timer.ElapsedMilliseconds
                if (($now - $lastUpdate) -gt 100) {
                    $percent = [math]::Round(($totalBytesRead / $totalBytes) * 100)
                    $downloadedMB = $totalBytesRead / 1MB
                    $totalMB = $totalBytes / 1MB
                    $speed = ($totalBytesRead - $lastBytesRead) / (($now - $lastUpdate) / 1000) / 1MB
                    
                    Write-ProgressBar -percent $percent -downloadedMB $downloadedMB -totalMB $totalMB -speed $speed
                    
                    $lastUpdate = $now
                    $lastBytesRead = $totalBytesRead
                }
            }
            
            Write-Host "`n"
            
            $fileStream.Close()
            $responseStream.Close()
            $response.Close()
            
        } catch {
            Write-Host "`n[ERROR] Download failed: $_" -ForegroundColor Red
            if ($fileStream) { $fileStream.Close() }
            if ($responseStream) { $responseStream.Close() }
            if ($response) { $response.Close() }
            throw
        }

        if (Test-Path $filePath) {
            $fileSize = (Get-Item $filePath).Length
            if ($fileSize -lt 1000) {
                Write-Host "[WARNING] Downloaded file is suspiciously small ($fileSize bytes)" -ForegroundColor Yellow
                $proceed = Read-Host "Do you want to proceed with installation? (Y/N)"
                if ($proceed -ne 'Y') {
                    Remove-Item $filePath -Force
                    Write-Host "[INFO] Installation cancelled by user." -ForegroundColor Yellow
                    return
                }
            }
            Write-Host "[SUCCESS] Download completed. Launching installer..." -ForegroundColor Green
            Start-Process -FilePath $filePath -Wait
            Write-Host "[SUCCESS] Installation completed successfully." -ForegroundColor Green
            Remove-Item $filePath -Force
        } else {
            Write-Host "[ERROR] Download failed." -ForegroundColor Red
            pause
            exit
        }

    } catch {
        Write-Host "[ERROR] An error occurred during download or installation: $_" -ForegroundColor Red
        Write-Host "[DEBUG] Download URL: $ExeLink" -ForegroundColor Yellow
        pause
        exit
    }
}


#===========================================================#
#                    Main Execution Block                    #
#===========================================================#
try {
    #Clear-Host
    Write-Host 
    Write-Host "+------------------------------------------------+" -ForegroundColor Yellow
    Write-Host " $name Installation Script"                         -ForegroundColor Yellow
    Write-Host "+------------------------------------------------+" -ForegroundColor Yellow
    Write-Host 

    # Detect site type and get links accordingly
    $siteType = Get-SiteType -Url $url
    Write-Host "[INFO] Detected site type: $siteType" -ForegroundColor Cyan
    
    $allLinks = @()
    
    # Get links based on site type
    switch ($siteType) {
        'GitHubRepo' {
            $allLinks += Get-GitHubRepoLinks -Owner $repoOwner -Repo $repoName
            if ($allLinks.Count -eq 0) {
                Write-Host "[INFO] Falling back to standard parsing..." -ForegroundColor Yellow
                $webResponse = Invoke-WebRequest -Uri $url -UseBasicParsing
                $allLinks += Get-DynamicContent -Url $url -InitialResponse $webResponse
            }
        }
        'GitHubRelease' {
            $allLinks += Get-GitHubReleaseAssetLinks -Owner $repoOwner -Repo $repoName -Tag $releaseTag
            if ($allLinks.Count -eq 0) {
                Write-Host "[INFO] No assets found in the release. Falling back to standard parsing..." -ForegroundColor Yellow
                $webResponse = Invoke-WebRequest -Uri $url -UseBasicParsing
                $allLinks += Get-DynamicContent -Url $url -InitialResponse $webResponse
            }
        }
        default {
            $webResponse = Invoke-WebRequest -Uri $url -UseBasicParsing
            $allLinks = @(Get-DynamicContent -Url $url -InitialResponse $webResponse | ForEach-Object {
                if ($_ -match '^https?://') {
                    $_
                } else {
                    # Convert from relative to absolute links
                    [System.Uri]::new([System.Uri]$url, $_).AbsoluteUri
                }
            })
        }
    }


    # Filter invalid links
    if ($extension) {
        $extensionPattern = "\.$extension$"
    } else {
        $extensionPattern = "\.[^\.]+$"
    }

    $filteredLinks = @($allLinks | Where-Object { 
        $_ -and $_.Length -gt 1 -and $_ -match '^https?://' -and $_ -match $extensionPattern
    })
    if ($pattern) {
        $patternLinks = @($filteredLinks | Where-Object { $_ -match $pattern })
        if ($patternLinks.Count -gt 0) {
            $filteredLinks = @($patternLinks)
        } else {
            Write-Host "[WARNING] No files matching pattern '$pattern' found. Showing all $extension files." -ForegroundColor Yellow
        }
    }

    if ($filteredLinks.Count -eq 0) {
        $debugFileName = "debug_page_content_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
        $debugFilePath = Join-Path $downloadPath $debugFileName
        
        if ($webResponse) {
            $webResponse.Content | Out-File -FilePath $debugFilePath -Encoding UTF8
        }
        
        Write-Host "[ERROR] No $extension files found." -ForegroundColor Red
        Write-Host "[DEBUG] Debug info saved to: $debugFilePath" -ForegroundColor Yellow
        Write-Host "`n[DEBUG] URL: $url" -ForegroundColor Yellow
        Write-Host "[DEBUG] Site Type: $siteType" -ForegroundColor Yellow
        
        pause
        exit
    }

    # Present options to user
    if ($filteredLinks.Count -gt 1) {
        Write-Host "`n_______________ Available Downloads _______________" -ForegroundColor Cyan
        $maxOptions = [Math]::Min(9, $filteredLinks.Count)
        
        if ($lucky -eq 1) {
            Write-Host "[INFO] Lucky mode: automatically selecting first option" -ForegroundColor Cyan
            $selectedLink = $filteredLinks[0]
            $fileName = try {
                $uri = [System.Uri]$selectedLink
                [System.Web.HttpUtility]::UrlDecode($uri.Segments[-1])
            } catch {
                $selectedLink
            }
            Write-Host "[INFO] Selected: $fileName" -ForegroundColor Cyan
        } else {
            # Function to get file size
            function Get-RemoteFileSize {
                param ([string]$url)
                try {
                    $response = Invoke-WebRequest -Uri $url -Method Head -UseBasicParsing
                    if ($response.Headers.'Content-Length') {
                        $size = [long]$response.Headers.'Content-Length'
                        if ($size -gt 1GB) {
                            return "{0:N2} GB" -f ($size / 1GB)
                        } elseif ($size -gt 1MB) {
                            return "{0:N2} MB" -f ($size / 1MB)
                        } elseif ($size -gt 1KB) {
                            return "{0:N2} KB" -f ($size / 1KB)
                        } else {
                            return "$size B"
                        }
                    }
                    return "Size unknown"
                } catch {
                    return "Size unknown"
                }
            }

            $displayItems = @()
            for ($i = 1; $i -le $maxOptions; $i++) {
                $link = $filteredLinks[$i - 1]
                $fileName = if ($link -is [string]) {
                    try {
                        $uri = [System.Uri]$link
                        [System.Web.HttpUtility]::UrlDecode($uri.Segments[-1])
                    } catch {
                        $link
                    }
                } else {
                    $link.ToString()
                }
                
                Write-Host "Analyzing file $i of $maxOptions..." -ForegroundColor Gray -NoNewline
                Write-Host "`r" -NoNewline
                $fileSize = Get-RemoteFileSize -url $link
                $displayItems += [PSCustomObject]@{
                    Index = $i
                    FileName = $fileName
                    Size = $fileSize
                }
            }
            
            Write-Host "`r" -NoNewline
            Write-Host (" " * 50) -NoNewline
            Write-Host "`r"

            foreach ($item in $displayItems) {
                Write-Host ("[$($item.Index)] {0,-50} ({1})" -f $item.FileName, $item.Size) -ForegroundColor White
            }
            
            Write-Host "---------------------------------------------------" -ForegroundColor Cyan
            Write-Host "`nPress a number key (1-$maxOptions) to select a file..." -ForegroundColor Yellow
            do {
                try {
                    $selection = Get-KeyPress
                    $validInput = $selection -ge 1 -and $selection -le $maxOptions
                } catch {
                    $validInput = $false
                }
            } while (-not $validInput)

            Write-Host $selection
            $selectedLink = $filteredLinks[$selection - 1]
        }
    } else {
        $selectedLink = $filteredLinks[0]
        $fileName = try {
            $uri = [System.Uri]$selectedLink
            $uri.Segments[-1]
        } catch {
            $selectedLink
        }
        Write-Host "[INFO] Single $extension file found: $fileName" -ForegroundColor Cyan
    }

    # Launch installation
    Invoke-ApplicationInstallation -ExeLink $selectedLink -DownloadPath $downloadPath

} catch {
    Write-Host "[ERROR] An error occurred: $_" -ForegroundColor Red
    
    if ($webResponse) {
        $debugFileName = "error_page_content_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
        $debugFilePath = Join-Path $downloadPath $debugFileName
        $webResponse.Content | Out-File -FilePath $debugFilePath -Encoding UTF8
        Write-Host "[DEBUG] Error page content saved to: $debugFilePath" -ForegroundColor Yellow
    }
    
    pause
    exit
}
