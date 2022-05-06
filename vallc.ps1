# Please change these accordingly:
# Upper/lowercase is important!

# Language codes: en_US, de_DE, ar_AE, es_ES, es_MX, fr_FR, id_ID, it_IT, ja_JP, ko_KR, pl_PL, pt_BR, ru_RU, th_TH, tr_TR, vi_VN, zh_TW
# The language code which you want the *text* to be in.
$textLang = 'en_US'
# The language code which you want the *voice* to be in.
$voiceLang = 'ja_JP'
# Your general Valorant region. (eu, na, kr, br, latam, ap)
$region = 'eu'
# The path to the game files. Go to your Valorant installation, the path below should always end in
# '.../ShooterGame/Content/Paks/'! Notice the / at the end.
$pakPath = 'D:/Riot Games/VALORANT/live/ShooterGame/Content/Paks/'
# You are done with the configuration.

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

	$found = 0
	$availableLocales = ''

	foreach ($config in $configs) {
		if ($config.valid_shards.live[0] -eq $region) {
			$found = 1
			$availableLocales = $config.locale_data.available_locales
			$patchUrl = $config.patch_url

			if ($patchUrl -ne $lastPatchUrl) {
				Write-Output 'Downloading new language files...'
				$patchUrl | Out-File -FilePath (-join($savePath, 'url.txt'))
				Start-Process -Wait -NoNewWindow -FilePath (-join($savePath, 'ManifestDownloader.exe')) -ArgumentList ($patchUrl,'-b','https://valorant.secure.dyn.riotcdn.net/channels/public/bundles','-l',$textLang,$voiceLang,'-o',$savePath,'-f','.+Text-WindowsClient.+')
				Write-Output 'Downloaded new language files!'
			} else {
			    Write-Output 'Up to date!'
			}

			if (!($availableLocales.Contains($textLang))) {
				Write-Error (-join('Invalid "textLang" value: ', $textLang))
				Write-Error (-join('Valid values are: ', [string]::Join(', ', $availableLocales)))
				Exit
			}
			if (!($availableLocales.Contains($voiceLang))) {
				Write-Error (-join('Invalid "voiceLang" value: ', $voiceLang))
				Write-Error (-join('Valid values are: ', [string]::Join(', ', $availableLocales)))
				Exit
			}
			break;
		}
	}

	if ($found -eq 0) {
		Write-Error (-join('Invalid "region" value: ', $region))
		Exit
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
