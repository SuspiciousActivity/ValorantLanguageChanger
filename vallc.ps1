$textLang = 'de_DE'
$voiceLang = 'ja_JP'
$region = 'eu'
$pakPath = 'G:/Valorant/Riot Games/VALORANT/live/ShooterGame/Content/Paks/'

$savePath = "$($env:LOCALAPPDATA)/ValorantLangChanger/"
$savePakPath = 'ShooterGame/Content/Paks/'

Write-Output '~ Valorant Language Changer ~'

if ($args.count -eq 0) {
	if (!(Test-Path $savePath)) {
		New-Item -Path $savePath -ItemType Directory
	}
	Invoke-Item $savePath
	Exit
}

# download/update lang files
Write-Output 'Checking for new language files...'
try {
	$lastPatchUrl = ''
	if (Test-Path (-join($savePath, 'url.txt'))) {
		$lastPatchUrl = Get-Content -Path (-join($savePath, 'url.txt'))
	}

	$patchConfig = ConvertFrom-Json (Invoke-WebRequest -Uri 'https://clientconfig.rpg.riotgames.com/api/v1/config/public?namespace=keystone.products.valorant.patchlines').Content
	$configs = $patchConfig.'keystone.products.valorant.patchlines.live'.platforms.win.configurations

	foreach ($config in $configs) {
		if ($config.valid_shards.live[0] -eq $region) {
			$patchUrl = $config.patch_url

			if ($patchUrl -ne $lastPatchUrl) {
				Write-Output 'Downloading new language files...'
				$patchUrl | Out-File -FilePath (-join($savePath, 'url.txt'))
				Start-Process -Wait -NoNewWindow -FilePath (-join($savePath, 'ManifestDownloader.exe')) -ArgumentList ($patchUrl,'-b','https://valorant.secure.dyn.riotcdn.net/channels/public/bundles','-l',$textLang,$voiceLang,'-o',$savePath,'-f','.+Text-WindowsClient.+')
				Write-Output 'Downloaded new language files!'
			} else {
			    Write-Output 'Up to date!'
			}
			break;
		}
	}
} catch {
	Write-Error 'Can not contact public valorant config'
	Exit
}

Write-Output 'Starting Valorant...'

# copy 'voice' text lang files to valorant (to fool the launcher)
Copy-Item (-join($savePath, $savePakPath, $voiceLang, '_Text-WindowsClient.pak')) (-join($pakPath, $voiceLang, '_Text-WindowsClient.pak'))
Copy-Item (-join($savePath, $savePakPath, $voiceLang, '_Text-WindowsClient.sig')) (-join($pakPath, $voiceLang, '_Text-WindowsClient.sig'))

Start-Process -FilePath $args[0] -ArgumentList $args[1..($args.count)]

Write-Output 'Waiting for Valorant to start...'

while (1) {
	$proc = Get-WmiObject -Class 'win32_process' -Filter 'name = "VALORANT.exe"'
	if ($proc) {
		break;
	}
	Start-Sleep -Milliseconds 100
}

Write-Output 'Changing text language files...'

# copy text lang files to valorant
Copy-Item (-join($savePath, $savePakPath, $textLang, '_Text-WindowsClient.pak')) (-join($pakPath, $voiceLang, '_Text-WindowsClient.pak'))
Copy-Item (-join($savePath, $savePakPath, $textLang, '_Text-WindowsClient.sig')) (-join($pakPath, $voiceLang, '_Text-WindowsClient.sig'))

Write-Output 'Have fun!'
