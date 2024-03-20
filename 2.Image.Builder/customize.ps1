param (
  [string] $buildConfigEncoded
)

$ErrorActionPreference = "Stop"

$binPaths = ""
$binDirectory = "C:\Users\Public\Downloads"
Set-Location -Path $binDirectory

. C:\AzureData\functions.ps1

Write-Host "Customize (Start): Resize OS Disk"
$osDriveLetter = "C"
$partitionSizeActive = (Get-Partition -DriveLetter $osDriveLetter).Size
$partitionSizeRange = Get-PartitionSupportedSize -DriveLetter $osDriveLetter
if ($partitionSizeActive + 1000000 -lt $partitionSizeRange.SizeMax) {
  Resize-Partition -DriveLetter $osDriveLetter -Size $partitionSizeRange.SizeMax
}
Write-Host "Customize (End): Resize OS Disk"

Write-Host "Customize (Start): Image Build Parameters"
$buildConfigBytes = [System.Convert]::FromBase64String($buildConfigEncoded)
$buildConfig = [System.Text.Encoding]::UTF8.GetString($buildConfigBytes) | ConvertFrom-Json
$machineType = $buildConfig.machineType
$gpuProvider = $buildConfig.gpuProvider
$binStorageHost = $buildConfig.binStorage.host
$binStorageAuth = $buildConfig.binStorage.auth
# $adminUsername = $buildConfig.dataPlatform.adminLogin.userName
# $adminPassword = $buildConfig.dataPlatform.adminLogin.userPassword
# $databaseUsername = $buildConfig.dataPlatform.jobDatabase.serviceLogin.userName
# $databasePassword = $buildConfig.dataPlatform.jobDatabase.serviceLogin.userPassword
$databaseHost = $buildConfig.dataPlatform.jobDatabase.host
$databasePort = $buildConfig.dataPlatform.jobDatabase.port
$renderEngines = $buildConfig.renderEngines
$enableCosmosDB = $false
if ($databaseHost -eq "") {
  $databaseHost = $(hostname)
  $databasePort = 27100
} else {
  $enableCosmosDB = $true
}
Write-Host "Machine Type: $machineType"
Write-Host "GPU Provider: $gpuProvider"
# Write-Host "Admin Username: $adminUsername"
# Write-Host "Admin Password: $adminPassword"
# Write-Host "Enable CosmosDB: $enableCosmosDB"
# Write-Host "Database Username: $databaseUsername"
# Write-Host "Database Password: $databasePassword"
Write-Host "Database Host: $databaseHost"
Write-Host "Database Port: $databasePort"
Write-Host "Render Engines: $renderEngines"
Write-Host "Customize (End): Image Build Parameters"

Write-Host "Customize (Start): Image Build Platform"
netsh advfirewall set allprofiles state off

Write-Host "Customize (Start): Chocolatey"
$processType = "chocolatey"
$installFile = "$processType.ps1"
$downloadUrl = "https://community.chocolatey.org/install.ps1"
(New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
RunProcess PowerShell.exe "-ExecutionPolicy Unrestricted -File .\$installFile" "$binDirectory\$processType"
$binPathChoco = "C:\ProgramData\chocolatey"
$binPaths += ";$binPathChoco"
Write-Host "Customize (End): Chocolatey"

Write-Host "Customize (Start): OpenSSL"
$processType = "openssl"
RunProcess "$binPathChoco\choco.exe" "install $processType --confirm --no-progress" "$binDirectory\$processType"
$binPathOpenSSL = "C:\Program Files\OpenSSL-Win64\bin"
$binPaths += ";$binPathOpenSSL"
Write-Host "Customize (End): OpenSSL"

Write-Host "Customize (Start): Python"
$processType = "python"
RunProcess "$binPathChoco\choco.exe" "install $processType --confirm --no-progress" "$binDirectory\$processType"
Write-Host "Customize (End): Python"

if ($machineType -eq "Workstation") {
  Write-Host "Customize (Start): Node.js"
  $processType = "nodejs"
  RunProcess "$binPathChoco\choco.exe" "install $processType --confirm --no-progress" "$binDirectory\$processType"
  Write-Host "Customize (End): Node.js"
}

Write-Host "Customize (Start): Git"
$processType = "git"
RunProcess "$binPathChoco\choco.exe" "install $processType --confirm --no-progress" "$binDirectory\$processType"
$binPathGit = "C:\Program Files\Git\bin"
$binPaths += ";$binPathGit"
Write-Host "Customize (End): Git"

Write-Host "Customize (Start): Visual Studio Build Tools"
$processType = "vsBuildTools"
RunProcess "$binPathChoco\choco.exe" "install visualstudio2022buildtools --package-parameters ""--add Microsoft.VisualStudio.Component.Windows11SDK.22621 --add Microsoft.VisualStudio.Component.VC.CMake.Project --add Microsoft.Component.MSBuild"" --confirm --no-progress" "$binDirectory\$processType"
$binPathCMake = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"
$binPathMSBuild = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\amd64"
$binPaths += ";$binPathCMake;$binPathMSBuild"
Write-Host "Customize (End): Visual Studio Build Tools"

Write-Host "Customize (Start): 7-Zip"
$processType = "7zip"
RunProcess "$binPathChoco\choco.exe" "install $processType --confirm --no-progress" "$binDirectory\$processType"
Write-Host "Customize (End): 7-Zip"

Write-Host "Customize (End): Image Build Platform"

if ($gpuProvider -eq "AMD") {
  $processType = "amd-gpu"
  if ($machineType -like "*NG*" -and $machineType -like "*v1*") {
    Write-Host "Customize (Start): AMD GPU (NG v1)"
    $installFile = "$processType.exe"
    $downloadUrl = "https://go.microsoft.com/fwlink/?linkid=2248541"
    (New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
    RunProcess .\$installFile "-install -log $binDirectory\$processType.log" $null
    Write-Host "Customize (End): AMD GPU (NG v1)"
  } elseif ($machineType -like "*NV*" -and $machineType -like "*v4*") {
    Write-Host "Customize (Start): AMD GPU (NV v4)"
    $installFile = "$processType.exe"
    $downloadUrl = "https://go.microsoft.com/fwlink/?linkid=2175154"
    (New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
    RunProcess .\$installFile "-install -log $binDirectory\$processType.log" $null
    Write-Host "Customize (End): AMD GPU (NV v4)"
  }
} elseif ($gpuProvider -eq "NVIDIA") {
  Write-Host "Customize (Start): NVIDIA GPU (GRID)"
  $processType = "nvidia-gpu-grid"
  $installFile = "$processType.exe"
  $downloadUrl = "https://go.microsoft.com/fwlink/?linkid=874181"
  (New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
  RunProcess .\$installFile "-s -n -log:$binDirectory\$processType" $null
  Write-Host "Customize (End): NVIDIA GPU (GRID)"

  Write-Host "Customize (Start): NVIDIA GPU (CUDA)"
  $versionPath = $buildConfig.versionPath.nvidiaCUDA
  $processType = "nvidia-gpu-cuda"
  $installFile = "cuda_${versionPath}_windows_network.exe"
  $downloadUrl = "$binStorageHost/NVIDIA/CUDA/$versionPath/$installFile$binStorageAuth"
  (New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
  RunProcess .\$installFile "-s -n -log:$binDirectory\$processType" $null
  Write-Host "Customize (End): NVIDIA GPU (CUDA)"

  Write-Host "Customize (Start): NVIDIA OptiX"
  $versionPath = $buildConfig.versionPath.nvidiaOptiX
  $processType = "nvidia-optix"
  $installFile = "NVIDIA-OptiX-SDK-$versionPath-win64.exe"
  $downloadUrl = "$binStorageHost/NVIDIA/OptiX/$versionPath/$installFile$binStorageAuth"
  (New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
  RunProcess .\$installFile "/S" $null
  $sdkDirectory = "C:\ProgramData\NVIDIA Corporation\OptiX SDK $versionPath\SDK"
  $buildDirectory = "$sdkDirectory\build"
  New-Item -ItemType Directory $buildDirectory
  $versionPath = $buildConfig.versionPath.nvidiaCUDAToolkit
  RunProcess "$binPathCMake\cmake.exe" "-B ""$buildDirectory"" -S ""$sdkDirectory"" -D CUDA_TOOLKIT_ROOT_DIR=""C:\\Program Files\\NVIDIA GPU Computing Toolkit\\CUDA\\$versionPath""" "$binDirectory\$processType-1"
  RunProcess "$binPathMSBuild\MSBuild.exe" """$buildDirectory\OptiX-Samples.sln"" -p:Configuration=Release" "$binDirectory\$processType-2"
  $binPaths += ";$buildDirectory\bin\Release"
  Write-Host "Customize (End): NVIDIA OptiX"
}

if ($machineType -eq "Storage" -or $machineType -eq "Scheduler") {
  Write-Host "Customize (Start): Azure CLI (x64)"
  $processType = "azure-cli"
  $installFile = "$processType.msi"
  $downloadUrl = "https://aka.ms/installazurecliwindowsx64"
  (New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
  RunProcess $installFile "/quiet /norestart /log $processType.log" $null
  Write-Host "Customize (End): Azure CLI (x64)"
}

if ($renderEngines -contains "PBRT") {
  Write-Host "Customize (Start): PBRT"
  $versionPath = $buildConfig.versionPath.renderPBRT
  $processType = "pbrt"
  $installPath = "C:\Program Files\PBRT"
  New-Item -ItemType Directory -Path "$installPath" -Force
  RunProcess "$binPathGit\git.exe" "clone --recursive https://github.com/mmp/$processType-$versionPath.git" "$binDirectory\$processType-1"
  RunProcess "$binPathCMake\cmake.exe" "-B ""$installPath"" -S $binDirectory\$processType-$versionPath" "$binDirectory\$processType-2"
  RunProcess "$binPathMSBuild\MSBuild.exe" """$installPath\PBRT-$versionPath.sln"" -p:Configuration=Release" "$binDirectory\$processType-3"
  $binPaths += ";$installPath\Release"
  Write-Host "Customize (End): PBRT"
}

if ($renderEngines -contains "Blender") {
  Write-Host "Customize (Start): Blender"
  $versionPath = $buildConfig.versionPath.renderBlender
  $processType = "blender"
  $installFile = "$processType-$versionPath-windows-x64.msi"
  $downloadUrl = "$binStorageHost/Blender/$versionPath/$installFile$binStorageAuth"
  (New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
  RunProcess $installFile "/quiet /norestart /log $processType.log" $null
  $binPaths += ";C:\Program Files\Blender Foundation\Blender 4.0"
  Write-Host "Customize (End): Blender"
}

if ($renderEngines -contains "Unreal" -or $renderEngines -contains "Unreal+PixelStream") {
  Write-Host "Customize (Start): Visual Studio Workloads"
  $versionPath = $buildConfig.versionPath.renderUnrealVS
  $processType = "unreal-visual-studio"
  $installFile = "VisualStudioSetup.exe"
  $downloadUrl = "$binStorageHost/VS/$versionPath/$installFile$binStorageAuth"
  (New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
  $componentIds = "--add Microsoft.Net.Component.4.8.SDK"
  $componentIds += " --add Microsoft.Net.Component.4.6.2.TargetingPack"
  $componentIds += " --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64"
  $componentIds += " --add Microsoft.VisualStudio.Component.VSSDK"
  $componentIds += " --add Microsoft.VisualStudio.Workload.NativeGame"
  $componentIds += " --add Microsoft.VisualStudio.Workload.NativeDesktop"
  $componentIds += " --add Microsoft.VisualStudio.Workload.NativeCrossPlat"
  $componentIds += " --add Microsoft.VisualStudio.Workload.ManagedDesktop"
  $componentIds += " --add Microsoft.VisualStudio.Workload.Universal"
  RunProcess .\$installFile "$componentIds --quiet --norestart" "$binDirectory\$processType"
  Write-Host "Customize (End): Visual Studio Workloads"

  Write-Host "Customize (Start): Unreal Engine Setup"
  $processType = "dotnet-fx3"
  dism /Online /NoRestart /LogPath:"$binDirectory\$processType" /Enable-Feature /FeatureName:NetFX3 /All
  Set-Location -Path C:\
  $versionPath = $buildConfig.versionPath.renderUnreal
  $processType = "unreal-engine"
  $installFile = "UnrealEngine-$versionPath-release.zip"
  $downloadUrl = "$binStorageHost/Unreal/$versionPath/$installFile$binStorageAuth"
  (New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
  Expand-Archive -Path $installFile

  $installPath = "C:\Program Files\Unreal"
  New-Item -ItemType Directory -Path "$installPath"
  Move-Item -Path "Unreal*\Unreal*\*" -Destination "$installPath"
  Remove-Item -Path "Unreal*" -Exclude "*.zip" -Recurse
  Set-Location -Path $binDirectory

  $buildPath = $installPath.Replace("\", "\\")
  $buildPath = "$buildPath\\Engine\\Binaries\\ThirdParty\\Windows\\DirectX\\x64\"
  $scriptFilePath = "$installPath\Engine\Source\Programs\ShaderCompileWorker\ShaderCompileWorker.Build.cs"
  $scriptFileText = Get-Content -Path $scriptFilePath
  $scriptFileText = $scriptFileText.Replace("DirectX.GetDllDir(Target) + ", "")
  $scriptFileText = $scriptFileText.Replace("d3dcompiler_47.dll", "$buildPath\d3dcompiler_47.dll")
  Set-Content -Path $scriptFilePath -Value $scriptFileText

  $installFile = "$installPath\Setup.bat"
  $scriptFilePath = $installFile
  $scriptFileText = Get-Content -Path $scriptFilePath
  $scriptFileText = $scriptFileText.Replace("/register", "/register /unattended")
  $scriptFileText = $scriptFileText.Replace("pause", "rem pause")
  Set-Content -Path $scriptFilePath -Value $scriptFileText

  RunProcess $installFile $null "$binDirectory\$processType-1"
  Write-Host "Customize (End): Unreal Engine Setup"

  Write-Host "Customize (Start): Unreal Project Files Generate"
  $installFile = "$installPath\GenerateProjectFiles.bat"
  $scriptFilePath = $installFile
  $scriptFileText = Get-Content -Path $scriptFilePath
  $scriptFileText = $scriptFileText.Replace("pause", "rem pause")
  Set-Content -Path $scriptFilePath -Value $scriptFileText
  $scriptFilePath = "$installPath\Engine\Build\BatchFiles\GenerateProjectFiles.bat"
  $scriptFileText = Get-Content -Path $scriptFilePath
  $scriptFileText = $scriptFileText.Replace("pause", "rem pause")
  Set-Content -Path $scriptFilePath -Value $scriptFileText
  RunProcess $installFile $null "$binDirectory\$processType-2"
  Write-Host "Customize (End): Unreal Project Files Generate"

  Write-Host "Customize (Start): Unreal Engine Build"
  [System.Environment]::SetEnvironmentVariable("MSBuildEnableWorkloadResolver", "false")
  [System.Environment]::SetEnvironmentVariable("MSBuildSDKsPath", "$installPath\Engine\Binaries\ThirdParty\DotNet\6.0.302\windows\sdk\6.0.302\Sdks")
  RunProcess "$binPathMSBuild\MSBuild.exe" """$installPath\UE5.sln"" -p:Configuration=""Development Editor"" -p:Platform=Win64 -restore" "$binDirectory\$processType-3"
  Write-Host "Customize (End): Unreal Engine Build"

  if ($renderEngines -contains "Unreal+PixelStream") {
    Write-Host "Customize (Start): Unreal Pixel Streaming"
    $versionPath = $buildConfig.versionPath.renderUnrealPixel
    $processType = "unreal-stream"
    $installFile = "UE$versionPath.zip"
    $downloadUrl = "$binStorageHost/Unreal/PixelStream/$versionPath/$installFile$binStorageAuth"
    (New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
    Expand-Archive -Path $installFile
    $installFile = "UE$versionPath\PixelStreamingInfrastructure-UE$versionPath\SignallingWebServer\platform_scripts\cmd\setup.bat"
    RunProcess .\$installFile $null "$binDirectory\$processType-signalling"
    $installFile = "UE$versionPath\PixelStreamingInfrastructure-UE$versionPath\Matchmaker\platform_scripts\cmd\setup.bat"
    RunProcess .\$installFile $null "$binDirectory\$processType-matchmaker"
    $installFile = "UE$versionPath\PixelStreamingInfrastructure-UE$versionPath\SFU\platform_scripts\cmd\setup.bat"
    RunProcess .\$installFile $null "$binDirectory\$processType-sfu"
    Write-Host "Customize (End): Unreal Pixel Streaming"
  }

  $binPathUnreal = "$installPath\Engine\Binaries\Win64"
  $binPaths += ";$binPathUnreal"

  if ($machineType -eq "Workstation") {
    Write-Host "Customize (Start): Unreal Editor"
    $shortcutPath = "$env:AllUsersProfile\Desktop\Unreal Editor.lnk"
    $scriptShell = New-Object -ComObject WScript.Shell
    $shortcut = $scriptShell.CreateShortcut($shortcutPath)
    $shortcut.WorkingDirectory = "$binPathUnreal"
    $shortcut.TargetPath = "$binPathUnreal\UnrealEditor.exe"
    $shortcut.Save()
    Write-Host "Customize (End): Unreal Editor"
  }
}

if ($renderEngines -contains "Maya") {
  Write-Host "Customize (Start): Maya"
  $versionPath = $buildConfig.versionPath.renderMaya
  $processType = "maya"
  $installFile = "Autodesk_Maya_${versionPath}_Update_Windows_64bit_dlm.zip"
  $downloadUrl = "$binStorageHost/Maya/$versionPath/$installFile$binStorageAuth"
  (New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
  Expand-Archive -Path $installFile
  Start-Process -FilePath .\Autodesk_Maya*\Autodesk_Maya*\Setup.exe -ArgumentList "--silent" -RedirectStandardOutput $processType-out -RedirectStandardError $processType-err
  Start-Sleep -Seconds 600
  $binPaths += ";C:\Program Files\Autodesk\Maya2024\bin"
  Write-Host "Customize (End): Maya"
}

if ($renderEngines -contains "Houdini") {
  Write-Host "Customize (Start): Houdini"
  $versionPath = $buildConfig.versionPath.renderHoudini
  $versionEULA = "2021-10-13"
  $processType = "houdini"
  $installFile = "$processType-$versionPath-win64-vc143.exe"
  $downloadUrl = "$binStorageHost/Houdini/$versionPath/$installFile$binStorageAuth"
  (New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
  if ($machineType -eq "Workstation") {
    $installArgs = "/MainApp=Yes"
  } else {
    $installArgs = "/HoudiniEngineOnly=Yes"
  }
  if ($renderEngines -contains "Maya") {
    $installArgs += " /EngineMaya=Yes"
  }
  if ($renderEngines -contains "Unreal") {
    $installArgs += " /EngineUnreal=Yes"
  }
  RunProcess .\$installFile "/S /AcceptEULA=$versionEULA $installArgs" "$binDirectory\$processType"
  $binPaths += ";C:\Program Files\Side Effects Software\Houdini $versionPath\bin"
  Write-Host "Customize (End): Houdini"
}

if ($machineType -eq "Scheduler") {
  Write-Host "Customize (Start): NFS Server"
  Install-WindowsFeature -Name "FS-NFS-Service"
  Write-Host "Customize (End): NFS Server"

  Write-Host "Customize (Start): AD Domain Services"
  Install-WindowsFeature -Name "AD-Domain-Services" -IncludeManagementTools
  Write-Host "Customize (End): AD Domain Services"

  Write-Host "Customize (Start): AD Users & Computers"
  $shortcutPath = "$env:AllUsersProfile\Desktop\AD Users & Computers.lnk"
  $scriptShell = New-Object -ComObject WScript.Shell
  $shortcut = $scriptShell.CreateShortcut($shortcutPath)
  $shortcut.WorkingDirectory = "%HOMEDRIVE%%HOMEPATH%"
  $shortcut.TargetPath = "%SystemRoot%\system32\dsa.msc"
  $shortcut.Save()
  Write-Host "Customize (End): AD Users & Computers"
} else {
  Write-Host "Customize (Start): NFS Client"
  $processType = "nfs-client"
  dism /Online /NoRestart /LogPath:"$binDirectory\$processType" /Enable-Feature /FeatureName:ClientForNFS-Infrastructure /All
  Write-Host "Customize (End): NFS Client"

  Write-Host "Customize (Start): AD Tools"
  $processType = "ad-tools" # RSAT: Active Directory Domain Services and Lightweight Directory Services Tools
  dism /Online /NoRestart /LogPath:"$binDirectory\$processType" /Add-Capability /CapabilityName:Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
  Write-Host "Customize (End): AD Tools"
}

if ($machineType -ne "Storage") {
  $versionPath = $buildConfig.versionPath.jobScheduler
  $installRoot = "C:\Deadline"
  $databasePath = "C:\DeadlineData"
  $certificateFile = "Deadline10Client.pfx"
  $binPathScheduler = "$installRoot\bin"

  Write-Host "Customize (Start): Deadline Download"
  $installFile = "Deadline-$versionPath-windows-installers.zip"
  $downloadUrl = "$binStorageHost/Deadline/$versionPath/$installFile$binStorageAuth"
  (New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
  Expand-Archive -Path $installFile
  Write-Host "Customize (End): Deadline Download"

  Set-Location -Path Deadline*
  if ($machineType -eq "Scheduler") {
    Write-Host "Customize (Start): Deadline Server"
    $processType = "deadline-repository"
    $installFile = "DeadlineRepository-$versionPath-windows-installer.exe"
    RunProcess .\$installFile "--mode unattended --dbLicenseAcceptance accept --prefix $installRoot --dbhost $databaseHost --mongodir $databasePath --installmongodb true" "$binDirectory\$processType"
    Move-Item -Path $env:TMP\installbuilder_installer.log -Destination $binDirectory\$processType.log
    Copy-Item -Path $databasePath\certs\$certificateFile -Destination $installRoot\$certificateFile
    New-NfsShare -Name "Deadline" -Path $installRoot -Permission ReadWrite
    Write-Host "Customize (End): Deadline Server"
  }

  Write-Host "Customize (Start): Deadline Client"
  $processType = "deadline-client"
  $installFile = "DeadlineClient-$versionPath-windows-installer.exe"
  $installArgs = "--mode unattended --prefix $installRoot"
  if ($machineType -eq "Scheduler") {
    $installArgs = "$installArgs --slavestartup false --launcherservice false"
  } else {
    if ($machineType -eq "Farm") {
      $workerStartup = "true"
    } else {
      $workerStartup = "false"
    }
    $installArgs = "$installArgs --slavestartup $workerStartup --launcherservice true"
  }
  RunProcess .\$installFile $installArgs "$binDirectory\$processType"
  Move-Item -Path $env:TMP\installbuilder_installer.log -Destination $binDirectory\$processType.log
  Set-Location -Path $binDirectory
  Write-Host "Customize (End): Deadline Client"

  Write-Host "Customize (Start): Deadline Scheduled Task"
  # $taskTrigger = New-ScheduledTaskTrigger -AtLogOn
  # $taskAction = New-ScheduledTaskAction -Execute "deadlinecommand" -Argument "-ChangeRepository Direct S:\ S:\Deadline10Client.pfx"
  # if ($machineType -eq "Scheduler") {
  #   $taskAction = New-ScheduledTaskAction -Execute "deadlinecommand" -Argument "-ChangeRepository Direct $installRoot $installRoot\$certificateFile"
  # }
  # Register-ScheduledTask -TaskName $jobSchedulerTaskName -Trigger $taskTrigger -Action $taskAction -User System -Force
  Write-Host "Customize (End): Deadline Scheduled Task"

  Write-Host "Customize (Start): Deadline Monitor"
  $shortcutPath = "$env:AllUsersProfile\Desktop\Deadline Monitor.lnk"
  $scriptShell = New-Object -ComObject WScript.Shell
  $shortcut = $scriptShell.CreateShortcut($shortcutPath)
  $shortcut.WorkingDirectory = $binPathScheduler
  $shortcut.TargetPath = "$binPathScheduler\deadlinemonitor.exe"
  $shortcut.Save()
  Write-Host "Customize (End): Deadline Monitor"

  $binPaths += ";$binPathScheduler"
}

if ($machineType -eq "Farm") {
  Write-Host "Customize (Start): Privacy Experience"
  $registryKeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OOBE"
  New-Item -ItemType Directory -Path $registryKeyPath -Force
  New-ItemProperty -Path $registryKeyPath -PropertyType DWORD -Name "DisablePrivacyExperience" -Value 1 -Force
  Write-Host "Customize (End): Privacy Experience"
}

if ($machineType -eq "Workstation") {
  Write-Host "Customize (Start): HP Anyware"
  $versionPath = $buildConfig.versionPath.pcoipAgent
  $processType = if ([string]::IsNullOrEmpty($gpuProvider)) {"pcoip-agent-standard"} else {"pcoip-agent-graphics"}
  $installFile = "${processType}_$versionPath.exe"
  $downloadUrl = "$binStorageHost/Teradici/$versionPath/$installFile$binStorageAuth"
  (New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
  RunProcess .\$installFile "/S /NoPostReboot /Force" "$binDirectory\$processType"
  Write-Host "Customize (End): HP Anyware"
}

if ($machineType -ne "Scheduler") {
  Write-Host "Customize (Start): WSL"
  $installFile = "wsl-ubuntu.appx"
  $downloadUrl = "https://aka.ms/wslubuntu"
  Install-PackageProvider -Name NuGet -Force
  Install-Module -Name PSWindowsUpdate -Force
  Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot
  (New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
  dism /Online /NoRestart /LogPath:"$binDirectory\wsl-appx" /Add-ProvisionedAppxPackage /PackagePath:$installFile /SkipLicense
  Write-Host "Customize (End): WSL"

  Write-Host "Customize (Start): PSTools"
  $installFile = "PSTools.zip"
  $downloadUrl = "https://download.sysinternals.com/files/$installFile"
  (New-Object System.Net.WebClient).DownloadFile($downloadUrl, (Join-Path -Path $pwd.Path -ChildPath $installFile))
  $binPathPSTools = "C:\Program Files\PSTools"
  Expand-Archive -Path $installFile -DestinationPath $binPathPSTools
  $binPaths += ";$binPathPSTools"
  Write-Host "Customize (End): PSTools"
}

Write-Host "Customize (PATH): $($binPaths.substring(1))"
setx PATH "$env:PATH$binPaths" /m
