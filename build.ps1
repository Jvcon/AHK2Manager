Import-Module Microsoft.PowerShell.Utility

$version = $args[0]
$cwd = (Get-Location).Path
$ahkpath = "C:\Users\Jacques\scoop\apps\autohotkey\current"
$ahk2exe = $ahkpath + "\Compiler\Ahk2Exe.exe"
$ahk64base = $ahkpath + "\v2\AutoHotkey64.exe"
$command = $ahk2exe + " /silent verbose " + " /base " + $ahk64base + " /out  $cwd\build\"

$setversion = ";@Ahk2Exe-SetVersion " + $version

Get-ChildItem “$cwd\*.ahk” | ForEach-Object {
    (Get-Content $_) | ForEach-Object  {$_ -Replace (";@Ahk2Exe-SetVersion " + '[0-9]+.[0-9]+.[0-9]+') , $setversion } | Set-Content $_
}

if (!(Test-Path -Path "$cwd\build")) {
    mkdir $cwd\build
}

foreach ($file in (Get-ChildItem -Path $cwd\*.ahk)) {
    Write-Host $file.BaseName
    Invoke-Expression($command + " /in $file")
    while ( !(Test-Path -Path "$cwd\build\$($file.BaseName).exe" )) {
        Start-Sleep 1
    }
}


if ((Test-Path -Path "$cwd\build\checksums_v$version.txt")) {
    Remove-Item -Path $cwd\build\checksums_v$version.txt
}

if ((Test-Path -Path "$cwd\build\AHK2Manager_v$version.zip")) {
    Remove-Item -Force -Path $cwd\build\AHK2Manager_v$version.zip
}

Compress-Archive -Path .\build\*.exe -DestinationPath .\build\AHK2Manager_v$version.zip

$value = (Get-FileHash -Path .\build\AHK2Manager_v$version.zip -Algorithm SHA256).Hash + "  AHK2Manager_v$version.zip"
Tee-Object -Append -InputObject $value -FilePath $cwd\build\checksums_v$version.txt


foreach ($file in (Get-ChildItem -Path $cwd\build\*.exe)) {
    Invoke-Expression("Remove-Item -Force -Path $file")
}
