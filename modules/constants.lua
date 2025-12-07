-- Defines the list of protected menu items that cannot be disabled.
-- Figured out this list by bruteforcing koreader, add anything I missed to this list.
return function(MenuDisabler)
    MenuDisabler.protected_items = {
        { section = "tools", item = "more_tools" },
        { section = "more_tools", item = "menu_disabler" },
        { section = "more_tools", item = "plugin_management" },
        { section = "more_tools", item = "patch_management" },
        { section = "KOMenu:menu_buttons", item = "filemanager_settings" },
        { section = "KOMenu:menu_buttons", item = "setting" },
        { section = "KOMenu:menu_buttons", item = "tools" },
        { section = "KOMenu:menu_buttons", item = "search" },
        { section = "KOMenu:menu_buttons", item = "plus_menu" },
        { section = "KOMenu:menu_buttons", item = "main" },
        { section = "exit_menu", item = "restart_koreader" },
        { section = "main", item = "ota_update" },
        { section = "setting", item = "device" },
        { section = "setting", item = "navigation" },
        { section = "filemanager_settings", item = "filemanager_display_mode" },
        { section = "navigation", item = "back_to_exit" },
        { section = "navigation", item = "back_in_filemanager" },
        { section = "navigation", item = "back_in_reader" },
        { section = "navigation", item = "backspace_as_back" },
        { section = "navigation", item = "physical_buttons_setup" },
        { section = "navigation", item = "android_volume_keys" },
        { section = "navigation", item = "android_haptic_feedback" },
        { section = "navigation", item = "android_back_button" },
        { section = "navigation", item = "opening_page_location_stack" },
        { section = "navigation", item = "skim_dialog_position" },
    }
end
