$savePath = "$($env:LOCALAPPDATA)/ValorantLangChanger/"
$configPath = -join($savePath, 'config.csv')
$savePakPath = 'ShooterGame/Content/Paks/'
$manifestDownloaderUrl = 'https://github.com/Morilli/ManifestDownloader/releases/download/v1.8_fix1/ManifestDownloader.exe'

function Get-Hash([string]$textToHash) {
	$hasher = new-object System.Security.Cryptography.MD5CryptoServiceProvider
	$toHash = [System.Text.Encoding]::UTF8.GetBytes($textToHash)
	$hashByteArray = $hasher.ComputeHash($toHash)
	foreach($byte in $hashByteArray) {
		$result += "{0:X2}" -f $byte
	}
	return $result;
}

$manifestDownloaderFile = -join((Get-Hash $manifestDownloaderUrl), '.exe')

Write-Host '~ Valorant Language Changer ~' -ForegroundColor Cyan
Write-Host '~ by EaZyCode ~' -ForegroundColor DarkGray
Write-Host ''

if ($args.count -eq 0) {
	Write-Host 'Hey! Thanks for using this tool!' -ForegroundColor Cyan
	Write-Host 'I will guide you through the setup now!' -ForegroundColor Cyan
	Write-Host ''
}

if (!(Test-Path $savePath)) {
	$_ = New-Item -Path $savePath -ItemType Directory
}

try {
	Write-Host 'Fetching VALORANT config from Riot Games...' -ForegroundColor Green
	$patchConfigs = (ConvertFrom-Json (Invoke-WebRequest -UseBasicParsing -Uri 'https://clientconfig.rpg.riotgames.com/api/v1/config/public?namespace=keystone.products.valorant.patchlines').Content).'keystone.products.valorant.patchlines.live'.platforms.win.configurations
} catch {
	Write-Host 'Error contacting Riot Games servers' -ForegroundColor Red
	Write-Host $_
	Read-Host
	Exit
}

$valid = @{}
$valid.regions = $patchConfigs | ForEach-Object {$_.id}

# Load config or guide the user to create a new one
$config = @{}
if (Test-Path $configPath) {
	try {
		Import-Csv (-join($savePath, 'config.csv')) | foreach -Process {$config.Add($_.Key, $_.Value)}
	} catch {
		# ignore
	}
}

$modified = 0
$tried = 0
while (!$valid.regions.Contains($config.region)) {
	$modified = 1
	if ($tried -eq 1) {
		Write-Host 'That is not a valid region!' -ForegroundColor Red
	}
	Write-Host 'Please enter your general region:' -ForegroundColor Yellow
	Write-Host (-join('(', [string]::Join(', ', $valid.regions), ')')) -ForegroundColor DarkGray
	$config.region = Read-Host
	$tried = 1
}

$regionConfig = $patchConfigs | Where-Object 'id' -eq $config.region
$valid.langs = $regionConfig | ForEach-Object {$_.locale_data.available_locales}

$tried = 0
while (!$valid.langs.Contains($config.voiceLang)) {
	$modified = 1
	if ($tried -eq 1) {
		Write-Host 'That is not a valid language!' -ForegroundColor Red
	}
	Write-Host 'Please enter your voice language:' -ForegroundColor Yellow
	Write-Host (-join('(', [string]::Join(', ', $valid.langs), ')')) -ForegroundColor DarkGray
	$config.voiceLang = Read-Host
	$tried = 1
}

$tried = 0
while (!$valid.langs.Contains($config.textLang)) {
	$modified = 1
	if ($tried -eq 1) {
		Write-Host 'That is not a valid language!' -ForegroundColor Red
	}
	Write-Host 'Please enter your text language:' -ForegroundColor Yellow
	Write-Host (-join('(', [string]::Join(', ', $valid.langs), ')')) -ForegroundColor DarkGray
	$config.textLang = Read-Host
	$tried = 1
}

$tried = 0
:out while (($null -eq $config.pakPath) -or (!$config.pakPath.EndsWith($savePakPath)) -or !(Test-Path $config.pakPath)) {
	$modified = 1
	if ($tried -eq 1) {
		Write-Host 'That is not the correct folder!' -ForegroundColor Red
	} else {
		Write-Host 'Trying to find VALORANT...' -ForegroundColor Green

		$drives = Get-PSDrive -PSProvider FileSystem | ForEach-Object {$_.Root}
		foreach ($drive in $drives) {
			$jsonPath = -join($drive, 'ProgramData\Riot Games\RiotClientInstalls.json')
			if (!(Test-Path $jsonPath)) {
				continue
			}

			$installs = Get-Content ($jsonPath) | ConvertFrom-Json
			$installPaths = $installs.associated_client.PSObject.Properties.Name
			foreach ($path in $installPaths) {
				$path = $path.Replace('\', '/')
				if ($path.EndsWith('VALORANT/live/')) {
					$config.pakPath = -join($path, $savePakPath)
					if (Test-Path $config.pakPath) {
						Write-Host 'Found it!' -ForegroundColor Green
						break out
					}
				}
			}
		}

		if (($null -eq $config.pakPath) -or !(Test-Path $config.pakPath)) {
			Write-Host 'Sorry, can''t find VALORANT.' -ForegroundColor Red
		}
	}
	if (!$FileBrowser) {
		Add-Type -AssemblyName System.Windows.Forms
		$FileBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
	}

	Write-Host 'A window to select a folder will now open.' -ForegroundColor Yellow
	Write-Host 'Please go to your VALORANT installation folder.' -ForegroundColor Yellow
	Write-Host (-join('In that folder, please find "', $savePakPath, '" and press Open.')) -ForegroundColor Yellow
	
	$status = $FileBrowser.ShowDialog()
	if ($status -eq 'OK') {
		$config.pakPath = $FileBrowser.SelectedPath.Replace('\', '/')
		if (!$config.pakPath.EndsWith('/')) {
			$config.pakPath = -join($config.pakPath, '/')
		}
	}
	$tried = 1
}

# save the config
if ($modified -eq 1) {
	$config.GetEnumerator() | Select Key, Value | Export-Csv (-join($savePath, 'config.csv'))
}

# continue setup
if ($args.count -eq 0) {
	$shell = New-Object -COM WScript.Shell

	$tried = 0
	while (($null -eq $shortcutPath) -or !(Test-Path $shortcutPath)) {
		if ($tried -eq 1) {
			Write-Host 'That is not a valid path to a shortcut!' -ForegroundColor Red
		}
		Write-Host 'Please drag your VALORANT shortcut into this window and press enter.' -ForegroundColor Yellow
		Write-Host '(The path to the shortcut should appear.)' -ForegroundColor DarkGray
		$shortcutPath = (Read-Host).Replace('"', '')
		$tried = 1
	}

	Write-Host 'Creating a new shortcut for you...' -ForegroundColor Green
	$newShortcutPath = (-join([Environment]::GetFolderPath("Desktop"), '/VALORANT Custom Language.lnk'))
	Copy-Item $shortcutPath $newShortcutPath
	$shortcut = $shell.CreateShortcut($newShortcutPath)
	$shortcut.Arguments = -join('-ExecutionPolicy Bypass -File "%localappdata%\ValorantLangChanger\vallc.ps1" "', $shortcut.TargetPath, '" ', $shortcut.Arguments)
	$shortcut.TargetPath = 'powershell.exe'
	$shortcut.Save()

	Write-Host 'Setting up all the files...' -ForegroundColor Green
	$psPath = $MyInvocation.MyCommand.Path
	Copy-Item $psPath (-join($savePath, 'vallc.ps1'))
	Invoke-WebRequest -UseBasicParsing -Uri $manifestDownloaderUrl -OutFile (-join($savePath, $manifestDownloaderFile))

	Write-Host 'Done! You can now close this window and start VALORANT from the new icon on your desktop!' -ForegroundColor Green
	Write-Host 'You can also delete this file now.' -ForegroundColor Green
	Read-Host
	Exit
}

$checkBefore = Get-WmiObject -Class 'win32_process' -Filter 'name = "VALORANT.exe"'
if ($checkBefore) {
	Write-Host 'Valorant is already running. Please close VALORANT first.' -ForegroundColor Red
	Write-Host 'Press enter to exit.' -ForegroundColor Red
	Read-Host
	Exit
}

# download/update lang files
Write-Host 'Checking for new language files...' -ForegroundColor DarkGray
try {
	$lastPatchUrl = ''
	if (Test-Path (-join($savePath, 'url.txt'))) {
		$lastPatchUrl = Get-Content -Path (-join($savePath, 'url.txt'))
	}

	$patchUrl = $regionConfig.patch_url

	if ($patchUrl -ne $lastPatchUrl) {
		Write-Host 'Downloading new language files...' -ForegroundColor Green
		$downloaderProcess = Start-Process -PassThru -Wait -NoNewWindow -FilePath (-join($savePath, $manifestDownloaderFile)) -ArgumentList ($patchUrl,'-b','https://valorant.secure.dyn.riotcdn.net/channels/public/bundles','-l',$config.textLang,$config.voiceLang,'-o',$savePath,'-f','.+Text-WindowsClient.+')
		if ($downloaderProcess.ExitCode -eq 0) {
			$patchUrl | Out-File -FilePath (-join($savePath, 'url.txt'))
			Write-Host 'Downloaded new language files!' -ForegroundColor Green
		} else {
			Write-Host 'Error trying to download new language files!' -ForegroundColor Red
			Read-Host
			Exit
		}
	} else {
		Write-Host 'Up to date!' -ForegroundColor Green
	}
} catch {
	Write-Error 'Can not check for new language files' -ForegroundColor Red
	Read-Host
	Exit
}

Write-Host 'Starting Valorant...' -ForegroundColor Green

# copy 'voice' text lang files to valorant (to fool the launcher)
Copy-Item (-join($savePath, $savePakPath, $config.voiceLang, '_Text-WindowsClient.pak')) (-join($config.pakPath, $config.voiceLang, '_Text-WindowsClient.pak'))
Copy-Item (-join($savePath, $savePakPath, $config.voiceLang, '_Text-WindowsClient.sig')) (-join($config.pakPath, $config.voiceLang, '_Text-WindowsClient.sig'))

Start-Process -FilePath $args[0] -ArgumentList $args[1..($args.count)]

Write-Host 'Waiting for Valorant to start...' -ForegroundColor DarkGray

while (1) {
	$proc = Get-WmiObject -Class 'win32_process' -Filter 'name = "VALORANT.exe"'
	if ($proc) {
		break;
	}
	Start-Sleep -Milliseconds 100
}

Write-Host 'Changing text language files...' -ForegroundColor Green

# copy text lang files to valorant
Copy-Item (-join($savePath, $savePakPath, $config.textLang, '_Text-WindowsClient.pak')) (-join($config.pakPath, $config.voiceLang, '_Text-WindowsClient.pak'))
Copy-Item (-join($savePath, $savePakPath, $config.textLang, '_Text-WindowsClient.sig')) (-join($config.pakPath, $config.voiceLang, '_Text-WindowsClient.sig'))

Write-Host 'Have fun!' -ForegroundColor Green
