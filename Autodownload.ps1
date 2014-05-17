#
# Autodownload script. Connects to the SFTP Server and grabs all new items that match the filters contained within dropbox.
# Created by Kyle Muir (kyle(dot)matthew(dot)muir(at)gmail(dot)com)
# https://github.com/Kyle-Muir
#

$ErrorActionPreference = "Stop"
$ftpServerAddress = "[ftp server address]"
$username = "[username]"
$password = "[password]"
$hostKey = "[host key]"
$dropboxDir = "[Dropbox local dir - for filters]" #optional, I used dropbox to host my filters so I could remotely edit them
$configuration = $configuration =[xml] (Get-Content "$dropboxDir\filters.xml")
$autoDownloadPath = "D:\Autodownloaded" #path to drop the downloaded items into.
$baseDir = "D:\Autodownload Script" #cant use "resolve-path ." because of the scheduled task.
$list = "$baseDir\list.txt"
$logDir = "$baseDir\Logs"
$listOfAlreadyDownloadedItems = Get-Content $list
$logDate = Get-Date –f "yyyy-MM-dd HH-mm-ss"
$logFile = "Log-$logDate.log"

$path = Join-Path $baseDir "WinSCPnet.dll"
Add-Type -Path $path

$sessionOptions = New-Object WinSCP.SessionOptions
$sessionOptions.Protocol = [WinSCP.Protocol]::Sftp
$sessionOptions.HostName = $ftpServerAddress
$sessionOptions.UserName = $username
$sessionOptions.Password = $password
$sessionOptions.SshHostKeyFingerprint = $hostKey

$session = New-Object WinSCP.Session

function Log($message) {
    $logFilePath = "$logDir\$logFile"
    Add-Content -LiteralPath $logFilePath -Value "`n$message"
}

function Process-RemoteFile($filePath, $fileName) {
    foreach($filter in $configuration.Filters.Filter) {
        if ($filePath -match $filter) {
            if ($listOfAlreadyDownloadedItems -notcontains $fileName) {
                $localPath = "$autoDownloadPath\$fileName"
                $start = Get-Date
                $session.GetFiles($filePath, $localPath).Check()
                $end = Get-Date
                Add-Content -LiteralPath $list -Value "`n$fileName"
                $timeSpan = $end - $start
                $seconds = $timeSpan.TotalSeconds
                Log "Added $fileName to the autodownloads directory. Download took $seconds seconds."
            }
        }
    }
}

function Get-FilesForDirectory($listDirectoryResults, $newPath) {
    foreach ($fileInfo in $listDirectoryResults.Files) {
        if ($fileInfo.FileType -ne "d") {
            $filePath = $newPath + "/" + $fileInfo.Name
            Process-RemoteFile $filePath $fileInfo.Name
        }
        if ($fileInfo.FileType -eq "d" -and $fileInfo.Name -ne ".." -and $fileInfo.Name -ne ".") {
            $fullDirectory = $newPath + '/' + $fileInfo.Name
            $listDirResult = $session.ListDirectory($fullDirectory)
            Get-FilesForDirectory $listDirResult $fullDirectory
        }
    }
}

try
{
    New-Item -ItemType "file" -Name $logFile -Path $logDir
    Log "Starting update at $(Get-Date)"
    $session.Open($sessionOptions)
    $dataDir = "/home/$username/data" #remote data directory
    $directory = $session.ListDirectory($dataDir)
    Get-FilesForDirectory $directory $dataDir
    Log "Update complete at $(Get-Date)"
}
finally
{
    $session.Dispose()
}
exit 0