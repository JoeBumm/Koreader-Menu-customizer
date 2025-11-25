# Menu Disabler Plugin for KOReader

## Overview
KOReader’s interface can feel cluttered or overwhelming, especially for new users. This plugin lets you customize the menu system by hiding any menu items you don’t need, helping you streamline your reading experience and focus on what matters most. 

![Menu Disabler Plugin Preview](https://github.com/user-attachments/assets/60db671c-e300-4b01-a230-5cc40e697f2a)
![Menu Disabler Plugin Layout](https://github.com/user-attachments/assets/b49946df-d7df-4020-ba3a-51ba979618d4)

## Features
- Hide Any Menu: Declutter your interface by toggling off unused Menus. (Ps: This just hides the menu, it doesn't disable native features)
- Custom Profiles: Save and switch between unlimited profiles (e.g. "Minimalist", "Night Mode") instantly.
- Quick Search: Find and hide specific settings fast with the built-in search bar.
- Sync Layouts: One-tap button to copy your File Manager setup to the Reader.
- Separate Controls: Customize File Manager and Reader menus independently.
- Instant Reset: Restore defaults with a single click if you change your mind

## Installation
1. Download the plugin ZIP file from the [Releases page](https://github.com/JoeBumm/menu_customizer.koplugin/releases/)
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
2. Navigate to: **More tools → Menu Disabler** (it's usually on the second page)

### Customizing Menus
- **Customize File Manager Menus:** (When in file browser)
  - Select "Customize File Manager Menus"
  - Tap any menu item to enable/disable it, and don't forge to save your changes
  - **Scroll to the last page and press Save**
- **Customize Reader Menus:** (When reading a document)
  - Select "Customize Reader Menus"
  - Tap any menu item to enable/disable it
  - **Scroll to the last page and press Save**
- **Reset All Menus to Default:**
  - Tap **"Reset everything to Default"** to restore all menus (File Manager and Reader) to their original state.
  - This will remove any customizations you've made and reload the default KOReader menu structure.
  - A confirmation dialog will appear before changes are applied.
- **Apply File Manager Layout to Reader:**
  - Tap **"Apply File Manager Layout to Reader"** to apply your current File Manager menu configuration to the Reader menus.
  - This is useful if you want a consistent menu layout across both modes. And it's fast if you are lazy.
  - You can still further customize the Reader menu after copying.

### Profiles (Layouts)
New in v2.0! You can now save your setups.
1.  Select **Profiles (Save/Load/Delete)**.
2.  Tap **➕ Save Current Setup** to name and store your current File Manager & Reader configuration.
3.  Tap any saved profile folder to **Load** it instantly.

### Protected Items
To prevent boot loops and crashes, critical system menus are **Locked (🔒)** and cannot be disabled:
* **Top-level Tabs** (Tools, Search, Settings, etc.)
* **Navigation & Device** menus (Required for page turns and power management)
* **OTA Updates** & **Plugin Management** (To ensure you can always update or fix the app)

### Saving Changes
1.  After making edits, tap **💾 SAVE & APPLY ALL CHANGES** at the top of the menu.
2.  A prompt will appear asking you to **Restart KOReader**.
3.  You must restart manually for changes to take effect.
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
- **Plugin not showing?** Ensure the plugin folder is named exactly `menu_disabler.koplugin`

## Support
For additional help:
- Open an issue on this repo

**Note:** Always back up your KOReader settings before making major changes.
