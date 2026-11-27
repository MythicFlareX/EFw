Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot

$ReadyDir = Join-Path $ProjectRoot "READY-MOD"
$ToolsDir = Join-Path $ProjectRoot ".tools"
$ExpectedJarName = "ApexCombat-AI-1.21.11.jar"
$DestinationJar = Join-Path $ReadyDir $ExpectedJarName

function Test-Java21 {
    param([string]$JavaExe)
    if (-not (Test-Path $JavaExe)) { return $false }
    try {
        $verOut = & $JavaExe -version 2>&1 | Out-String
        return ($verOut -match 'version "21(\.|\")')
    } catch {
        return $false
    }
}

$JavaExe = $null
if ($env:JAVA_HOME) {
    $candidate = Join-Path $env:JAVA_HOME "bin\java.exe"
    if (Test-Java21 $candidate) { $JavaExe = $candidate }
}
if (-not $JavaExe) {
    $cmd = Get-Command java -ErrorAction SilentlyContinue
    if ($cmd -and (Test-Java21 $cmd.Source)) {
        $JavaExe = $cmd.Source
        $env:JAVA_HOME = Split-Path (Split-Path $cmd.Source -Parent) -Parent
    }
}
if (-not $JavaExe) {
    $portableJdk = Get-ChildItem -Path (Join-Path $ToolsDir "jdk-21*") -Filter "java.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($portableJdk -and (Test-Java21 $portableJdk.FullName)) {
        $JavaExe = $portableJdk.FullName
        $env:JAVA_HOME = Split-Path (Split-Path $JavaExe -Parent) -Parent
    }
}
if (-not $JavaExe) {
    New-Item -ItemType Directory -Force -Path $ToolsDir | Out-Null
    $zipPath = Join-Path $ToolsDir "temurin21.zip"
    $apiUrl = "https://api.adoptium.net/v3/binary/latest/21/ga/windows/x64/jdk/hotspot/normal/eclipse"
    Write-Host "Downloading portable Temurin JDK 21..."
    Invoke-WebRequest -Uri $apiUrl -OutFile $zipPath -UseBasicParsing
    Expand-Archive -Path $zipPath -DestinationPath $ToolsDir -Force
    $extracted = Get-ChildItem -Path (Join-Path $ToolsDir "jdk-21*") -Filter "java.exe" -Recurse | Select-Object -First 1
    if (-not $extracted) { throw "Failed to locate java.exe inside downloaded JDK 21 archive." }
    $JavaExe = $extracted.FullName
    $env:JAVA_HOME = Split-Path (Split-Path $JavaExe -Parent) -Parent
}
$env:PATH = "$(Join-Path $env:JAVA_HOME 'bin');$env:PATH"

$GradleCmd = Join-Path $ProjectRoot "gradlew.bat"
if (-not (Test-Path $GradleCmd)) {
    $gradleBin = Get-Command gradle -ErrorAction SilentlyContinue
    if ($gradleBin) {
        $GradleCmd = $gradleBin.Source
    } else {
        New-Item -ItemType Directory -Force -Path $ToolsDir | Out-Null
        $gradleZip = Join-Path $ToolsDir "gradle-9.2.1-bin.zip"
        Write-Host "Downloading Gradle 9.2.1..."
        Invoke-WebRequest -Uri "https://services.gradle.org/distributions/gradle-9.2.1-bin.zip" -OutFile $gradleZip -UseBasicParsing
        Expand-Archive -Path $gradleZip -DestinationPath $ToolsDir -Force
        $GradleCmd = Join-Path $ToolsDir "gradle-9.2.1\bin\gradle.bat"
    }
}

Write-Host "Running clean build and tests..."
& $GradleCmd clean build --no-daemon
if ($LASTEXITCODE -ne 0) {
    throw "Gradle build failed with exit code $LASTEXITCODE."
}

$libsDir = Join-Path $ProjectRoot "build\libs"
$builtJar = Get-ChildItem -Path $libsDir -Filter "*.jar" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notlike "*-sources.jar" -and $_.Name -notlike "*-javadoc.jar" -and $_.Name -notlike "*-dev.jar" } |
    Sort-Object Length -Descending |
    Select-Object -First 1

if (-not $builtJar) {
    $builtJar = Get-ChildItem -Path $libsDir -Filter "*.jar" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notlike "*-sources.jar" } |
        Sort-Object Length -Descending |
        Select-Object -First 1
}

if (-not $builtJar -or -not (Test-Path $builtJar.FullName)) {
    throw "Build failed: no output JAR found in build\libs."
}
if ($builtJar.Length -lt 10240) {
    throw "Build failed: output JAR ($($builtJar.Length) bytes) is suspiciously small."
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($builtJar.FullName)
try {
    $entryNames = $zip.Entries | ForEach-Object { $_.FullName }
    if ($entryNames -notcontains "fabric.mod.json") {
        throw "JAR verification failed: missing fabric.mod.json."
    }
    $metaEntry = $zip.GetEntry("fabric.mod.json")
    $reader = New-Object System.IO.StreamReader($metaEntry.Open())
    $metaJson = $reader.ReadToEnd()
    $reader.Close()
    if ($metaJson -notmatch '"id"\s*:\s*"apexcombat-ai"') {
        throw "JAR verification failed: fabric.mod.json missing expected mod id 'apexcombat-ai'."
    }
    $classEntries = $entryNames | Where-Object { $_ -like "*.class" }
    if (-not $classEntries -or $classEntries.Count -eq 0) {
        throw "JAR verification failed: no compiled .class entries found."
    }
    if ($classEntries -notcontains "com/apexcombat/ai/ApexCombatAI.class") {
        throw "JAR verification failed: main entrypoint class com/apexcombat/ai/ApexCombatAI.class missing."
    }
} finally {
    $zip.Dispose()
}

New-Item -ItemType Directory -Force -Path $ReadyDir | Out-Null
Copy-Item -Path $builtJar.FullName -Destination $DestinationJar -Force
Write-Host "SUCCESS: Verified installable JAR copied to $DestinationJar ($((Get-Item $DestinationJar).Length) bytes)."
