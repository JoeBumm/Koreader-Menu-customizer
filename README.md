# Menu Disabler Plugin for KOReader
![GitHub release (latest by date)](https://img.shields.io/github/v/release/JoeBumm/Koreader-Menu-customizer?style=for-the-badge&color=orange) 
![GitHub all releases](https://img.shields.io/github/downloads/JoeBumm/Koreader-Menu-customizer/total?style=for-the-badge&color=red) ![Platform](https://img.shields.io/badge/Platform-KOReader-success?style=for-the-badge&logo=koreader)

## "Where did all the buttons go?" — You, hopefully.

KOReader is amazing. Its menus? They have more buttons than a spaceship cockpit. 
This plugin lets you hide the clutter so you can actually, *read*.

![Menu Disabler Plugin Preview](https://github.com/user-attachments/assets/60db671c-e300-4b01-a230-5cc40e697f2a)

## What can it do?
*   **Hide the Useless Stuff**: Toggle off menus you never touch. (It hides them; it doesn't delete them. I'm not a monster.)
*   **Profiles**: Create setups like "Deep Reading," "Night Mode," or "I Am Overwhelmed."
*   **One-Click Sync**: Too lazy to configure the Reader menu after fixing the File Manager? Me too. Hit "Apply File Manager Layout to Reader" and be done with it.
*   **Safety First**: I locked the critical stuff (Search, Settings, etc.) so you can't accidentally brick your experience and blame me.

## How to Install (The Boring Part)
1.  Grab the ZIP from [Releases](https://github.com/JoeBumm/menu_customizer.koplugin/releases/).
2.  Unzip it. You want the `menu_disabler.koplugin` folder.
3.  Throw that folder into your KOReader plugins directory (`koreader/plugins/`).
4.  Restart KOReader.

## How to Use
1.  Go to **More tools → Menu Disabler**.
2.  Pick a mode (File Manager or Reader).
3.  **Tap to hide/show items.** X means visible. [] means "gone to the shadow realm."
4.  **SCROLL DOWN AND HIT SAVE.** If you don't save, it didn't happen.

## Help! I Broke It!
If you somehow managed to hide the "Un-hide" button or your device is acting possessed:
*   **The Nuclear Option**: Delete `filemanager_menu_order.lua` and `reader_menu_order.lua` from your `koreader/settings/` folder.
*   **The "I Give Up" Option**: Delete the plugin folder. KOReader will forgive you.

## Support
Found a bug? Have a suggestion? Want to tell me I'm funny?
Open an issue.

**Disclaimer:** Always back up your settings. I tested this, but I'm just a person on the internet.
