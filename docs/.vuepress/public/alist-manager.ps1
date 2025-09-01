# Alist Manager Script for Windows
# Version: 1.8.0 (�Զ�������� PS5.1 + PS7+)
# Author: Troray (��д by ChatGPT)

# -----------------------------
# �Զ���� PowerShell �汾�������������
$psVersion = $PSVersionTable.PSVersion.Major

if ($psVersion -ge 7) {
    # PowerShell 7+ UTF-8
    chcp 65001 > $null
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $EncName = "UTF-8"
} else {
    # PowerShell 5.1 / CMD GBK
    chcp 936 > $null
    [Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding(936)
    $EncName = "GBK"
}

# ��ʾ�û���ǰ���루��ѡ��
Write-Host "��ǰ�ն˱���: $EncName" -ForegroundColor Yellow
# -----------------------------

param($Action, $InstallPath)
if (-not $Action) { $Action = "menu" }
if (-not $InstallPath) { $InstallPath = "C:\alist" }

# ��ɫ����
$Green  = "Green"
$Red    = "Red"
$Yellow = "Yellow"
$White  = "White"
$ServiceName = "AlistService"

# -----------------------------
# �������
function Write-Info($msg, $color="White") {
    $validColors = @("Black","DarkBlue","DarkGreen","DarkCyan","DarkRed",
                     "DarkMagenta","DarkYellow","Gray","DarkGray","Blue",
                     "Green","Cyan","Red","Magenta","Yellow","White")
    if ($validColors -contains $color) {
        [Console]::ForegroundColor = $color
        [Console]::WriteLine($msg)
        [Console]::ResetColor()
    } else {
        [Console]::WriteLine($msg)
    }
}

# �����ļ�
function Download-File($url, $output) {
    Try {
        Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing -TimeoutSec 30
        return $true
    } Catch {
        Write-Info "����ʧ��: $url" $Red
        return $false
    }
}

# ��ȡ���°汾
function Get-LatestVersion {
    $apiUrl = "https://dapi.alistgo.com/v0/version/latest"
    Try {
        $json = Invoke-RestMethod -Uri $apiUrl -TimeoutSec 10
        return $json
    } Catch {
        return $null
    }
}

# ��װ Alist
function Install-Alist {
    if (-Not (Test-Path $InstallPath)) {
        New-Item -ItemType Directory -Path $InstallPath | Out-Null
    }

    $latest = Get-LatestVersion
    if ($null -eq $latest) {
        Write-Info "��ȡ�汾��Ϣʧ�ܣ�ʹ�� GitHub Դ" $Yellow
        $url = "https://github.com/alist-org/alist/releases/latest/download/alist-windows-amd64.zip"
    } else {
        $version = $latest.version
        Write-Info "���°汾: $version" $Green
        $url = "https://github.com/alist-org/alist/releases/download/v$version/alist-windows-amd64.zip"
    }

    $tmpZip = "$env:TEMP\alist.zip"
    if (-Not (Download-File $url $tmpZip)) { exit 1 }

    Expand-Archive -Path $tmpZip -DestinationPath $InstallPath -Force
    Remove-Item $tmpZip -Force

    Write-Info "Alist �Ѱ�װ�� $InstallPath" $Green
    Write-Info "����: `"$InstallPath\alist.exe server`"" $Yellow
}

# ���� Alist
function Update-Alist {
    if (-Not (Test-Path "$InstallPath\alist.exe")) {
        Write-Info "δ��⵽�Ѱ�װ�� Alist�����Ȱ�װ" $Red
        exit 1
    }
    Write-Info "��ʼ����..." $Green
    Install-Alist
}

# ж�� Alist
function Uninstall-Alist {
    if (Test-Path $InstallPath) {
        Remove-Item -Recurse -Force $InstallPath
        Write-Info "Alist ��ж��" $Green
    } else {
        Write-Info "δ��⵽��װĿ¼ $InstallPath" $Yellow
    }
}

# ע�����
function Service-Install {
    if (-Not (Test-Path "$InstallPath\alist.exe")) {
        Write-Info "���Ȱ�װ Alist ��ע�����" $Red
        exit 1
    }
    Write-Info "����ע�� Windows ���� $ServiceName ..." $Green
    sc.exe create $ServiceName binPath= "`"$InstallPath\alist.exe`" server" start= auto DisplayName= "Alist Service" | Out-Null
    sc.exe description $ServiceName "Alist Web �ļ�����" | Out-Null
    Write-Info "����ע����ɣ�������Ϊ��������" $Green
}

# ɾ������
function Service-Remove {
    Write-Info "����ɾ�� Windows ���� $ServiceName ..." $Yellow
    sc.exe stop $ServiceName | Out-Null
    sc.exe delete $ServiceName | Out-Null
    Write-Info "������ɾ��" $Green
}

function Service-Start   { sc.exe start $ServiceName }
function Service-Stop    { sc.exe stop $ServiceName }
function Service-Restart { Service-Stop; Start-Sleep -Seconds 2; Service-Start }
function Service-Status  { sc.exe query $ServiceName }

# �˵�
function Show-Menu {
    while ($true) {
        Clear-Host
        Write-Info "`n=== Alist Windows ����ű� ===`n" $Green
        Write-Info "1. ��װ Alist" $White
        Write-Info "2. ���� Alist" $White
        Write-Info "3. ж�� Alist" $White
        Write-Info "-------------------------" $White
        Write-Info "4. ע��Ϊ Windows ���� (��������)" $White
        Write-Info "5. ɾ�� Windows ����" $White
        Write-Info "6. ��������" $White
        Write-Info "7. ֹͣ����" $White
        Write-Info "8. ��������" $White
        Write-Info "9. �鿴����״̬" $White
        Write-Info "-------------------------" $White
        Write-Info "0. �˳�" $White
        $choice = Read-Host "������ѡ��"

        switch ($choice) {
            "1" { Install-Alist; Pause }
            "2" { Update-Alist; Pause }
            "3" { Uninstall-Alist; Pause }
            "4" { Service-Install; Pause }
            "5" { Service-Remove; Pause }
            "6" { Service-Start; Pause }
            "7" { Service-Stop; Pause }
            "8" { Service-Restart; Pause }
            "9" { Service-Status; Pause }
            "0" { exit 0 }
            default { Write-Info "��Чѡ��" $Red; Pause }
        }
    }
}

# ������
switch ($Action) {
    "install"         { Install-Alist }
    "update"          { Update-Alist }
    "uninstall"       { Uninstall-Alist }
    "service-install" { Service-Install }
    "service-remove"  { Service-Remove }
    "start"           { Service-Start }
    "stop"            { Service-Stop }
    "restart"         { Service-Restart }
    "status"          { Service-Status }
    "menu"            { Show-Menu }
    default           { Show-Menu }
}
