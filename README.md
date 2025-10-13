# Menu Disabler Plugin for KOReader

## Overview
KOReader’s interface can feel cluttered or overwhelming, especially for new users. This plugin lets you customize the menu system by hiding any menu items you don’t need, helping you streamline your reading experience and focus on what matters most.

![Menu Disabler Plugin Preview](https://github.com/user-attachments/assets/60db671c-e300-4b01-a230-5cc40e697f2a)
![Menu Disabler Plugin Layout](https://github.com/user-attachments/assets/fd7a9599-b89a-4bc6-a835-1cb67a3f8a84)


## Installation
1. Download the plugin ZIP file from the [Releases page](https://github.com/JoeBumm/menu_customizer.koplugin/releases/)
2. Extract the ZIP to get the `menu_disabler.koplugin` folder
3. Transfer this folder to your KOReader plugins directory:
   - **Android:** `/sdcard/koreader/plugins/`
   - **Linux:** `~/.config/koreader/plugins/`
   - **Kobo:** `/mnt/onboard/.adds/koreader/plugins/`
   - **Kindle:** `/mnt/us/koreader/plugins/`
4. Restart KOReader

⚠️ Known Issue: "NEW:" Labels Appearing on Menu Items
If you notice unexpected "NEW:" tags appearing on many menu entries (including core features like Book information or Status bar), this is a known KOReader backend issue related to how menu rendering works.

It occurs after customizing menus or using the Menu Disabler plugin, and can make KOReader appear broken — but it’s only a cosmetic problem.

Workaround:
Reset the Menu Disabler plugin to default settings. This removes all incorrect labels.

For more details, see the related discussion:
👉 Issue https://github.com/JoeBumm/Koreader-Menu-customizer/issues/2

## Usage
### Accessing the Plugin
1. Open KOReader's main menu
2. Navigate to: **More tools → Menu Disabler**

### Customizing Menus
- **File Manager Menus:** (When in file browser)
  - Select "Customize File Manager Menus"
  - Tap any menu item to enable/disable it
  - **Scroll to the last page and press Save**
- **Reader Menus:** (When reading a document)
  - Select "Customize Reader Menus"
  - Tap any menu item to enable/disable it
  - **Scroll to the last page and press Save**
- **Reset to Default:**
  - Tap **"Reset everything to Default"** to restore all menus (File Manager and Reader) to their original state.
  - This will remove any customizations you've made and reload the default KOReader menu structure.
  - A confirmation dialog will appear before changes are applied.
- **Copy File-Manager to Reader:**
  - Tap **"Copy File-Manager settings to Reader"** to apply your current File Manager menu configuration to the Reader menus.
  - This is useful if you want a consistent menu layout across both modes. And it's fast if you are lazy.
  - You can still further customize the Reader menu after copying.

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
1. **Access settings directory** using a file manager (By using a usb connection or by using ssh):
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
- **Changes not appearing?** After disabling a menu **Scroll to the last page and press Save** and Remember to restart KOReader after saving
- **Menu items reappearing?** Some core menus are protected and cannot be disabled
- **Plugin not showing?** Ensure the plugin folder is named exactly `menu_disabler.koplugin`

## Support
For additional help:
- Open an issue on this repo
- Visit the [KOReader forums](https://github.com/koreader/koreader/discussions)
- Check the `DEBUG.md` file for advanced troubleshooting

**Note:** Always back up your KOReader settings before making major changes.
