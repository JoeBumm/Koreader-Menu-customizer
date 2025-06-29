# Menu Disabler Plugin for KOReader

## Overview
This plugin allows you to customize KOReader's menu system by hiding specific menus and plugins. It helps streamline your reading experience by removing unnecessary menu items while protecting critical functions like plugin management.

## Installation
1. Download the plugin ZIP file from the [Releases page](link-to-releases)
2. Extract the ZIP to get the `menu_disabler.koplugin` folder
3. Transfer this folder to your KOReader plugins directory:
   - **Android:** `/sdcard/koreader/plugins/`
   - **Linux:** `~/.config/koreader/plugins/`
   - **Kobo:** `/mnt/onboard/.adds/koreader/plugins/`
   - **Kindle:** `/mnt/us/koreader/plugins/`
4. Restart KOReader

## Usage
### Accessing the Plugin
1. Open KOReader's main menu
2. Navigate to: **More tools → Menu Disabler**

### Customizing Menus
- **File Manager Menus:** (When in file browser)
  - Select "Customize File Manager Menus"
  - Tap any menu item to enable/disable it
- **Reader Menus:** (When reading a document)
  - Select "Customize Reader Menus"
  - Tap any menu item to enable/disable it

### Protected Items
Some critical items cannot be disabled on some devices:
- More Tools menu
- Plugin Management
- Patch Management

### Saving Changes
1. After making changes, tap **💾 Save Changes**
2. **Restart KOReader** for changes to take effect
3. Changes are automatically saved to:
   - `settings/filemanager_menu_order.lua`
   - `settings/reader_menu_order.lua`

### Resetting to Defaults
- To reset a single menu type:
  - Tap **↺ Reset All (Enable All)** at the bottom of the customization screen
- To reset both menus:
  - Use **Reset everything to default** in the main plugin menu

## Troubleshooting
### If KOReader Crashes Completely / Refuses to open 
1. **Access settings directory** using a file manager (By using a usb connection or by ssh):
   - Android: `/sdcard/koreader/settings/`
   - Linux: `~/.config/koreader/settings/`
   - Kobo: `/mnt/onboard/.adds/koreader/settings/`
   - Kindle: `/mnt/us/koreader/settings/`

2. **Delete configuration files:**
   - `filemanager_menu_order.lua`
   - `reader_menu_order.lua`

3. **If crashes persist:**
   - Remove the plugin:
     - Delete `menu_disabler.koplugin` from your plugins directory
   Still persists? 
   - Reset KOReader settings:
     - Delete the entire `settings` directory (backup first if possible)

### Common Issues
- **Changes not appearing?** Remember to restart KOReader after saving
- **Menu items reappearing?** Some core menus are protected and cannot be disabled
- **Plugin not showing?** Ensure the plugin folder is named exactly `menu_disabler.koplugin`

## Recovery Options
1. **Manual Recovery Mode:**
   - Hold "R" key while starting KOReader (on devices with keyboards)
   - Select "Reset settings to defaults"

2. **ADB Recovery (Android):**
   ```bash
   adb shell rm -rf /sdcard/koreader/settings/menu_*.lua
   ```

3. **SSH Recovery (Linux/Kobo):**
   ```bash
   ssh root@kobo-ip
   rm /mnt/onboard/.adds/koreader/settings/menu_*.lua
   ```

## Support
For additional help:
- Open an issue on this repo
- Visit the [KOReader forums](https://github.com/koreader/koreader/discussions)
- Check the `DEBUG.md` file for advanced troubleshooting

**Note:** Always back up your KOReader settings before making major changes.
