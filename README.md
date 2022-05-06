# Valorant Language Changer
Changes the text language for valorant while keeping the voice language.

Want to hear those uwu-voices from japan but don't understand anything that is written there? It's your lucky day!

## Usage
1. Change your ingame language to whatever you want the *voice* language to be.
2. Download this repository (from the release tab) and put the contents into a folder.
3. Right-click the vallc.ps1 file and "Run with PowerShell". A folder should open now. (If it doesn't, please go to `%localappdata%` and create a folder called `ValorantLangChanger`.)
4. Put the vallc.ps1 file and the ManifestDownloader.exe into that folder.
5. Open vallc.ps1 in your favorite text editor. Change the top 4 values accordingly and save it.
6. Copy your Valorant shortcut, then right-click the copy and select Properties.
7. In the target field, there should be something like this: `"D:\Riot Games\Riot Client\RiotClientServices.exe" --launch-product=valorant --launch-patchline=live`.
8. Infront of that, put `powershell.exe -File "%localappdata%\ValorantLangChanger\vallc.ps1" `. Notice the space at the end.
9. The full target should now look like this: `powershell.exe -File "%localappdata%\ValorantLangChanger\vallc.ps1" "D:\Riot Games\Riot Client\RiotClientServices.exe" --launch-product=valorant --launch-patchline=live`. Press Ok.
10. You can now use this shortcut to launch Valorant with different languages.

## Is this a virus??
No. If your antivirus has a problem with the exe file, it comes from [here](https://github.com/Morilli/ManifestDownloader). You can download the latest release there if you want. You can view the source of the ps1 script as well.

## Thanks to
https://github.com/Morilli/ManifestDownloader this downloads the latest language files!

## Legal

Riot Games, VALORANT, and any associated logos are trademarks, service marks, and/or registered trademarks of Riot Games, Inc.

This project is in no way affiliated with, authorized, maintained, sponsored or endorsed by Riot Games, Inc or any of its affiliates or subsidiaries.

I, the project owner and creator, am not responsible for any legalities that may arise in the use of this project. Use at your own risk.
