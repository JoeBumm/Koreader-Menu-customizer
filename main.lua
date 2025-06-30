local WidgetContainer = require("ui/widget/container/widgetcontainer")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local ConfirmBox = require("ui/widget/confirmbox")
local Menu = require("ui/widget/menu")
local ButtonTable = require("ui/widget/buttontable")
local Screen = require("device").screen
local lfs = require("libs/libkoreader-lfs")
local Device = require("device")
local _ = require("gettext")

-- Register with More Tools menu BEFORE plugin initialization
require("ui/plugin/insert_menu").add("menu_disabler")

local MenuDisabler = WidgetContainer:extend{
    name = "menu_disabler",

    is_doc_only = false,
}

local protected_items = {
    { section = "tools", item = "more_tools" },
    { section = "more_tools", item = "plugin_management" },
    { section = "more_tools", item = "patch_management" },
}

-- Define default menu structures as local functions
local function getDefaultMenuStructure()
    local base_structure = {
        ["KOMenu:menu_buttons"] = {
            "filemanager_settings",
            "setting",
            "tools",
            "search",
            "plus_menu",
            "main",
        },
        filemanager_settings = {
            "filemanager_display_mode",
            "filebrowser_settings",
            "show_filter",
            "sort_by",
            "reverse_sorting",
            "sort_mixed",
            "start_with",
        },
        setting = {
            "frontlight",
            "night_mode",
            "network",
            "screen",
            "taps_and_gestures",
            "navigation",
            "document",
            "language",
            "device",
        },
        document = {
            "document_metadata_location",
            "document_metadata_location_move",
            "document_auto_save",
            "document_end_action",
            "language_support",
        },
        device = {
            "keyboard_layout",
            "external_keyboard",
            "font_ui_fallbacks",
            "time",
            "units",
            "device_status_alarm",
            "charging_led",
            "autostandby",
            "autosuspend",
            "autoshutdown",
            "ignore_sleepcover",
            "ignore_open_sleepcover",
            "cover_events",
            "ignore_battery_optimizations",
            "mass_storage_settings",
            "file_ext_assoc",
            "screenshot",
        },
        navigation = {
            "back_to_exit",
            "back_in_filemanager",
            "back_in_reader",
            "backspace_as_back",
            "physical_buttons_setup",
            "android_volume_keys",
            "android_haptic_feedback",
            "android_back_button",
            "opening_page_location_stack",
            "skim_dialog_position",
        },
        network = {
            "network_wifi",
            "network_proxy",
            "network_powersave",
            "network_restore",
            "network_info",
            "network_before_wifi_action",
            "network_after_wifi_action",
            "network_dismiss_scan",
            "ssh",
        },
        screen = {
            "screensaver",
            "autodim",
            "screen_rotation",
            "screen_dpi",
            "screen_eink_opt",
            "autowarmth",
            "color_rendering",
            "screen_timeout",
            "fullscreen",
            "screen_notification",
        },
        taps_and_gestures = {
            "gesture_manager",
            "gesture_overview",
            "gesture_intervals",
            "ignore_hold_corners",
            "screen_disable_double_tap",
            "menu_activate",
        },
        tools = {
            "read_timer",
            "calibre",
            "exporter",
            "statistics",
            "cloud_storage",
            "move_to_archive",
            "wallabag",
            "news_downloader",
            "text_editor",
            "profiles",
            "qrclipboard",
            "more_tools",
        },
        more_tools = {
            "auto_frontlight",
            "battery_statistics",
            "book_shortcuts",
            "synchronize_time",
            "keep_alive",
            "doc_setting_tweak",
            "terminal",
            "plugin_management",
            "patch_management",
            "advanced_settings",
            "developer_options",
        },
        search = {
            "search_settings",
            "dictionary_lookup",
            "dictionary_lookup_history",
            "vocabbuilder",
            "wikipedia_lookup",
            "wikipedia_history",
            "file_search",
            "file_search_results",
            "find_book_in_calibre_catalog",
            "opds",
        },
        search_settings = {
            "dictionary_settings",
            "wikipedia_settings",
        },
        main = {
            "history",
            "open_last_document",
            "favorites",
            "collections",
            "mass_storage_actions",
            "ota_update",
            "help",
            "exit_menu",
        },
        help = {
            "quickstart_guide",
            "search_menu",
            "report_bug",
            "system_statistics",
            "version",
            "about",
        },
        plus_menu = {},
        exit_menu = {
            "restart_koreader",
            "sleep",
            "poweroff",
            "reboot",
            "start_bq",
            "exit",
        }
    }
    
    -- Filter out device-specific items that don't exist
    if not Device:hasExitOptions() then
        base_structure.exit_menu = nil
    end
    
    return base_structure
end

-- Define properly formatted output structure with comments
local function getDefaultOutputStructure()
    return {
        filemanager_settings = {
            "filemanager_display_mode",
            "filebrowser_settings",
            "----------------------------",
            "show_filter",
            "sort_by",
            "reverse_sorting",
            "sort_mixed",
            "----------------------------",
            "start_with",
        },
        setting = {
            "-- common settings",
            "-- those that don't exist will simply be skipped during menu gen",
            "frontlight", -- if Device:hasFrontlight()
            "night_mode",
            "----------------------------",
            "network",
            "screen",
            "----------------------------",
            "taps_and_gestures",
            "navigation",
            "document",
            "----------------------------",
            "language",
            "device",
            "-- end common settings",
        },
        document = {
            "document_metadata_location",
            "document_metadata_location_move",
            "document_auto_save",
            "document_end_action",
            "language_support",
        },
        device = {
            "keyboard_layout",
            "external_keyboard",
            "font_ui_fallbacks",
            "----------------------------",
            "time",
            "units",
            "device_status_alarm",
            "charging_led", -- if Device:canToggleChargingLED()
            "autostandby",
            "autosuspend",
            "autoshutdown",
            "ignore_sleepcover",
            "ignore_open_sleepcover",
            "cover_events",
            "ignore_battery_optimizations",
            "mass_storage_settings", -- if Device:canToggleMassStorage()
            "file_ext_assoc",
            "screenshot",
        },
        navigation = {
            "back_to_exit",
            "back_in_filemanager",
            "back_in_reader",
            "backspace_as_back",
            "----------------------------",
            "physical_buttons_setup",
            "----------------------------",
            "android_volume_keys",
            "android_haptic_feedback",
            "android_back_button",
            "----------------------------",
            "opening_page_location_stack",
            "skim_dialog_position",
        },
        network = {
            "network_wifi",
            "network_proxy",
            "network_powersave",
            "network_restore",
            "network_info",
            "network_before_wifi_action",
            "network_after_wifi_action",
            "network_dismiss_scan",
            "----------------------------",
            "ssh",
        },
        screen = {
            "screensaver",
            "autodim",
            "----------------------------",
            "screen_rotation",
            "----------------------------",
            "screen_dpi",
            "screen_eink_opt",
            "autowarmth",
            "color_rendering",
            "----------------------------",
            "screen_timeout",
            "fullscreen",
            "----------------------------",
            "screen_notification",
        },
        taps_and_gestures = {
            "gesture_manager",
            "gesture_overview",
            "gesture_intervals",
            "----------------------------",
            "ignore_hold_corners",
            "screen_disable_double_tap",
            "----------------------------",
            "menu_activate",
        },
        tools = {
            "read_timer",
            "calibre",
            "exporter",
            "statistics",
            "cloud_storage",
            "move_to_archive",
            "wallabag",
            "news_downloader",
            "text_editor",
            "profiles",
            "qrclipboard",
            "----------------------------",
            "more_tools",
        },
        more_tools = {
            "auto_frontlight",
            "battery_statistics",
            "book_shortcuts",
            "synchronize_time",
            "keep_alive",
            "doc_setting_tweak",
            "terminal",
            "----------------------------",
            "plugin_management",
            "patch_management",
            "advanced_settings",
            "developer_options",
        },
        search = {
            "search_settings",
            "----------------------------",
            "dictionary_lookup",
            "dictionary_lookup_history",
            "vocabbuilder",
            "----------------------------",
            "wikipedia_lookup",
            "wikipedia_history",
            "----------------------------",
            "file_search",
            "file_search_results",
            "find_book_in_calibre_catalog",
            "----------------------------",
            "opds",
        },
        search_settings = {
            "dictionary_settings",
            "wikipedia_settings",
        },
        main = {
            "history",
            "open_last_document",
            "----------------------------",
            "favorites",
            "collections",
            "----------------------------",
            "mass_storage_actions", -- if Device:canToggleMassStorage()
            "----------------------------",
            "ota_update", -- if Device:hasOTAUpdates()
            "help",
            "----------------------------",
            "exit_menu",
        },
        help = {
            "quickstart_guide",
            "----------------------------",
            "search_menu",
            "----------------------------",
            "report_bug",
            "----------------------------",
            "system_statistics", -- if enabled (Plugin)
            "version",
            "about",
        },
        plus_menu = {},
        exit_menu = {
            "restart_koreader",
            "sleep",
            "poweroff",
            "reboot",
            "start_bq",
            "exit",
        }
    }
end

-- Function to get all plugin names
function MenuDisabler:getAvailablePlugins()
    local plugins = {}
    
    -- Look for plugins in koreader/plugins directory
    local plugin_paths = {
        "plugins", -- Standard plugins
        "plugins/patch" -- Patch management
    }
    
    for _, path in ipairs(plugin_paths) do
        local full_path = self.settings_path:gsub("settings$", "") .. path
        if lfs.attributes(full_path, "mode") == "directory" then
            for file in lfs.dir(full_path) do
                if file ~= "." and file ~= ".." then
                    local plugin_dir = full_path .. "/" .. file
                    if lfs.attributes(plugin_dir, "mode") == "directory" then
                        local main_file = plugin_dir .. "/main.lua"
                        if lfs.attributes(main_file, "mode") == "file" then
                            -- Try to find the plugin name
                            local f = io.open(main_file, "r")
                            if f then
                                local content = f:read("*all")
                                f:close()
                                
                                -- Look for addToMainMenu function
                                local pattern = "function.-:addToMainMenu%(%s*menu_items%s*%)%s*menu_items%.([%w_]+)%s*="
                                local name = content:match(pattern)
                                
                                if name then
                                    plugins[name] = file
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return plugins
end

function MenuDisabler:init()
    self.ui.menu:registerToMainMenu(self)
    
    -- Initialize settings path
    self.settings_path = require("datastorage"):getSettingsDir()

end

-- Helper function to read existing menu order file
function MenuDisabler:readMenuOrderFile(filename)
    local filepath = self.settings_path .. "/" .. filename
    if lfs.attributes(filepath, "mode") == "file" then
        local chunk = loadfile(filepath)
        if chunk then
            local success, result = pcall(chunk)
            if success and type(result) == "table" then
                return result
            end
        end
    end
    return nil
end

-- Get list of main sections that users can customize
function MenuDisabler:getCustomizableSections()
    return {
        "tools",
        "more_tools", 
        "search",
        "main",
        "setting",
        "filemanager_settings",
        "help",
        "plus_menu"
    }
end

-- Get currently enabled structure including disabled items
function MenuDisabler:getCurrentEnabledStructure(menu_type, filename)
    local current_menu = self:readMenuOrderFile(filename)
    local default_structure = getDefaultMenuStructure()
    
    if current_menu then
        -- Preserve disabled items
        self.existing_disabled = current_menu["KOMenu:disabled"] or {}
        return current_menu
    else
        self.existing_disabled = {}
        return default_structure
    end
end

-- Collect all disabled menu items including plugins
function MenuDisabler:collectDisabledItems()
    local disabled_items = {}
    local default_structure = getDefaultMenuStructure()
    local customizable_sections = self:getCustomizableSections()
    local available_plugins = self:getAvailablePlugins()
    
    -- First add existing disabled items
    for _, item in ipairs(self.existing_disabled) do
        table.insert(disabled_items, item)
    end
    
    -- Collect disabled native items
    for _, section in ipairs(customizable_sections) do
        if default_structure[section] then
            for _, item in ipairs(default_structure[section]) do
                if item ~= "----------------------------" then
                    if self.working_enabled[section] and self.working_enabled[section][item] == false then
                        if not self:isInList(disabled_items, item) then
                            table.insert(disabled_items, item)
                        end
                    end
                end
            end
        end
    end
    
    -- Collect disabled plugins
    for plugin_name, _ in pairs(available_plugins) do
        local prefixed_name = "plugin_" .. plugin_name
        local is_enabled = false
        
        -- Check all sections to see if this plugin is enabled
        for _, section in ipairs(customizable_sections) do
            if self.working_enabled[section] and self.working_enabled[section][prefixed_name] == true then
                is_enabled = true
                break
            end
        end
        
        if not is_enabled then
            if not self:isInList(disabled_items, plugin_name) then
                table.insert(disabled_items, plugin_name)
            end
        end
    end
    
    return disabled_items
end

-- Helper function to check if item is in list
function MenuDisabler:isInList(list, item)
    for _, v in ipairs(list) do
        if v == item then
            return true
        end
    end
    return false
end

-- Save menu order file with proper formatting
function MenuDisabler:saveMenuOrderFile(filename, enabled_structure)
    local filepath = self.settings_path .. "/" .. filename
    local file = io.open(filepath, "w")
    if not file then return false, _("Could not write to file") end

    local output_structure = getDefaultOutputStructure()
    
    -- Ensure protected items are included in the output
    for _, protected in ipairs(protected_items) do
        local section = protected.section
        local item = protected.item
        
        -- Add to output structure if missing
        local found = false
        if output_structure[section] then
            for _, existing_item in ipairs(output_structure[section]) do
                if existing_item == item then
                    found = true
                    break
                end
            end
        end
        
        if not found then
            if not output_structure[section] then
                output_structure[section] = {}
            end
            table.insert(output_structure[section], item)
        end
    end
    
    file:write("return {\n")
    
    -- Write all regular sections
    for section, default_items in pairs(output_structure) do
        file:write("    " .. section .. " = {\n")
        
        for _, item in ipairs(default_items) do
            -- Handle comments (lines starting with --)
            if item:sub(1, 2) == "--" then
                file:write("        " .. item .. "\n")
            -- Handle separators (exactly "----------------------------")
            elseif item == "----------------------------" then
                file:write('        "' .. item .. '",\n')
            -- Handle regular menu items
            else
                -- Only include if enabled
                local should_include = true
                if self.working_enabled[section] then
                    should_include = self.working_enabled[section][item] == true
                end
                
                if should_include then
                    file:write('        "' .. item .. '",\n')
                end
            end
        end
        
        -- Add any plugins that are enabled for this section
        if self.working_enabled[section] then
            for item, enabled in pairs(self.working_enabled[section]) do
                if enabled == true and item:match("^plugin_") then
                    -- Write plugin name without "plugin_" prefix
                    file:write('        "' .. item:sub(8) .. '",\n')
                end
            end
        end
        
        file:write("    },\n")
    end
    
    -- Add disabled items section at the end
    local disabled_items = self:collectDisabledItems()
    file:write('    ["KOMenu:disabled"] = {\n')
    if #disabled_items > 0 then
        for _, item in ipairs(disabled_items) do
            file:write('        "' .. item .. '",\n')
        end
    else
        file:write('        -- No disabled menu items\n')
    end
    file:write("    },\n")
    
    file:write("}\n")
    file:close()
    return true
end

-- Show menu disabler interface
function MenuDisabler:showMenuDisabler(menu_type)
    local filename = menu_type .. "_menu_order.lua"
    
    -- Get currently enabled structure
    local enabled_structure = self:getCurrentEnabledStructure(menu_type, filename)
    local default_structure = getDefaultMenuStructure()
    
    -- Create working copy - track which items are enabled per section
    self.working_enabled = {}
    local customizable_sections = self:getCustomizableSections()
    
    for _, section in ipairs(customizable_sections) do
        self.working_enabled[section] = {}
        if enabled_structure[section] then
            for _, item in ipairs(enabled_structure[section]) do
                if item ~= "----------------------------" then
                    self.working_enabled[section][item] = true
                end
            end
        end
    end
    
    -- Add plugin management to the list
    self:addPluginManagement()
    
    -- Force protected items to be enabled
    for _, protected in ipairs(protected_items) do
        local section = protected.section
        local item = protected.item
        if not self.working_enabled[section] then
            self.working_enabled[section] = {}
        end
        self.working_enabled[section][item] = true
    end
    
    self:showItemList(menu_type, filename)
end

-- Add plugin management options - MODIFIED TO ADD TO MORE_TOOLS
function MenuDisabler:addPluginManagement()
    local available_plugins = self:getAvailablePlugins()
    local customizable_sections = self:getCustomizableSections()
    
    for plugin_name, _ in pairs(available_plugins) do
        -- Create a prefixed name to avoid conflicts
        local prefixed_name = "plugin_" .. plugin_name
        
        -- Check if plugin is already in any section
        local found = false
        for _, section in ipairs(customizable_sections) do
            if self.working_enabled[section] and self.working_enabled[section][prefixed_name] ~= nil then
                found = true
                break
            end
        end
        
        -- CHANGED: Default to more_tools instead of plus_menu
        if not found then
            if not self.working_enabled.more_tools then
                self.working_enabled.more_tools = {}
            end
            -- Only add if not already present
            if self.working_enabled.more_tools[prefixed_name] == nil then
                self.working_enabled.more_tools[prefixed_name] = true
            end
        end
    end
end

-- Show list of items that can be disabled/enabled
function MenuDisabler:showItemList(menu_type, filename)
    local menu_items = {}
    local default_structure = getDefaultMenuStructure()
    local customizable_sections = self:getCustomizableSections()
    local available_plugins = self:getAvailablePlugins()
    
    -- Add header
    table.insert(menu_items, {
        text = _("=== TAP TO TOGGLE DISABLE/ENABLE ==="),
        enabled = false,
    })
    
    -- Process each customizable section
    for _, section in ipairs(customizable_sections) do
        if default_structure[section] or self.working_enabled[section] then
            -- Add section header
            local section_title = section:gsub("_", " "):upper()
            table.insert(menu_items, {
                text = "--- " .. section_title .. " ---",
                enabled = false,
            })
            
            -- Get all items for this section (native + plugins)
            local all_items = {}
            
            -- Add native items from default structure
            if default_structure[section] then
                for _, item in ipairs(default_structure[section]) do
                    if item ~= "----------------------------" then
                        table.insert(all_items, item)
                    end
                end
            end
            
            -- Add plugin items
            if self.working_enabled[section] then
                for item, enabled in pairs(self.working_enabled[section]) do
                    if item:match("^plugin_") and enabled ~= nil then
                        table.insert(all_items, item)
                    end
                end
            end
            
            -- Show all items except protected ones
            for _, item in ipairs(all_items) do
                -- Check if this item is protected
                local is_protected = false
                for _, protected in ipairs(protected_items) do
                    if protected.section == section and protected.item == item then
                        is_protected = true
                        break
                    end
                end
                
                if not is_protected then
                    local is_plugin = item:match("^plugin_")
                    local is_enabled = self.working_enabled[section] and 
                                      self.working_enabled[section][item] == true
                    local status = is_enabled and "✓ ENABLED" or "🚫 DISABLED"
                    local display_name = item
                    
                    -- Special handling for plugins
                    if is_plugin then
                        local plugin_base = item:gsub("^plugin_", "")
                        display_name = available_plugins[plugin_base] and 
                            ("Plugin: " .. plugin_base) or 
                            ("Plugin: " .. item)
                    else
                        display_name = item:gsub("_", " ")
                    end
                    
                    table.insert(menu_items, {
                        text = "  " .. display_name .. " (" .. status .. ")",
                        callback = function()
                            -- Toggle enabled status
                            if not self.working_enabled[section] then
                                self.working_enabled[section] = {}
                            end
                            self.working_enabled[section][item] = not self.working_enabled[section][item]
                            UIManager:close(self.item_dialog)
                            self:showItemList(menu_type, filename)
                        end,
                    })
                end
            end
        end
    end
    
    -- Add separator and action buttons
    table.insert(menu_items, {
        text = "",
        enabled = false,
    })
    
    table.insert(menu_items, {
        text = _("💾 Save Changes"),
        callback = function()
            UIManager:close(self.item_dialog)
            self:saveChanges(menu_type, filename)
        end,
    })
    
    table.insert(menu_items, {
        text = _("↺ Reset All (Enable All)"),
        callback = function()
            UIManager:close(self.item_dialog)
            self:resetAllItems(menu_type, filename)
        end,
    })
    
    table.insert(menu_items, {
        text = _("✕ Cancel"),
        callback = function()
            UIManager:close(self.item_dialog)
        end,
    })
    
    self.item_dialog = Menu:new{
        title = _("Menu Disabler") .. " - " .. menu_type:gsub("^%l", string.upper),
        item_table = menu_items,
        width = Screen:getWidth() * 0.9,
        height = Screen:getHeight() * 0.9,
    }
    
    UIManager:show(self.item_dialog)
end

-- Save changes to file
function MenuDisabler:saveChanges(menu_type, filename)
    local default_structure = getDefaultMenuStructure()
    local enabled_structure = {}
    local customizable_sections = self:getCustomizableSections()
    
    -- Copy the complete default structure
    for section_name, items in pairs(default_structure) do
        enabled_structure[section_name] = {}
        if type(items) == "table" then
            for _, item in ipairs(items) do
                enabled_structure[section_name][#enabled_structure[section_name] + 1] = item
            end
        end
    end
    
    -- Now filter out disabled items from customizable sections
    local total_enabled = 0
    local total_available = 0
    
    for _, section in ipairs(customizable_sections) do
        if self.working_enabled[section] then
            local filtered_items = {}
            
            -- Add default items
            if enabled_structure[section] then
                for _, item in ipairs(enabled_structure[section]) do
                    if item == "----------------------------" then
                        -- Always keep separators
                        table.insert(filtered_items, item)
                    else
                        total_available = total_available + 1
                        if self.working_enabled[section][item] == true then
                            table.insert(filtered_items, item)
                            total_enabled = total_enabled + 1
                        end
                    end
                end
            end
            
            -- Add enabled plugins
            for item, enabled in pairs(self.working_enabled[section]) do
                if enabled == true and item:match("^plugin_") then
                    table.insert(filtered_items, item:sub(8))
                    total_available = total_available + 1
                    total_enabled = total_enabled + 1
                end
            end
            
            enabled_structure[section] = filtered_items
        end
    end
    
    local success, err = self:saveMenuOrderFile(filename, enabled_structure)
    
    if success then
        local disabled_count = total_available - total_enabled
        local message = disabled_count > 0 and 
            string.format(_("Configuration saved!\n\nEnabled: %d items\nDisabled: %d items\n\nRestart KOReader to see changes."), 
                         total_enabled, disabled_count) or
            _("All menu items enabled!\n\nRestart KOReader to see changes.")
            
        UIManager:show(ConfirmBox:new{
            text = message,
            ok_text = _("OK"),
        })
    else
        UIManager:show(InfoMessage:new{
            text = _("Error saving changes: ") .. (err or _("Unknown error")),
            timeout = 5,
        })
    end
end

-- Reset all items (enable everything)
function MenuDisabler:resetAllItems(menu_type, filename)
    UIManager:show(ConfirmBox:new{
        text = _("Enable all menu items?\n\nThis will restore the default menu layout."),
        ok_text = _("Enable All"),
        cancel_text = _("Cancel"),
        ok_callback = function()
            local filepath = self.settings_path .. "/" .. filename
            if lfs.attributes(filepath, "mode") == "file" then
                os.remove(filepath)
            end
            
            UIManager:show(InfoMessage:new{
                text = _("All menu items enabled!\n\nRestart KOReader to see changes."),
                timeout = 3,
            })
        end,
    })
end

-- Updated addToMainMenu method with new copy button
function MenuDisabler:addToMainMenu(menu_items)
    menu_items.menu_disabler = {
        text = _("Menu Disabler"),
        sub_item_table = {
            {
                text = _("Customize File Manager Menus (When you are on the file browser)"),
                callback = function()
                    self:showMenuDisabler("filemanager")
                end
            },
            {
                text = _("Customize Reader Menus (When you are inside a document)"),
                callback = function()
                    self:showMenuDisabler("reader")
                end
            },
            {
                text = _("Copy File-Manager settings to Reader"),
                callback = function()
                    self:copyFileManagerToReader()
                end
            },
            {
                text = _("Reset everything to default"),
                callback = function()
                    UIManager:show(ConfirmBox:new{
                        text = _("This will enable all menu items by restoring default layouts.\n\nContinue?"),
                        ok_text = _("Enable All"),
                        cancel_text = _("Cancel"),
                        ok_callback = function()
                            self:enableAllMenus()
                        end,
                    })
                end
            }
        }
    }
    return menu_items
end

-- New method to copy file manager configuration to reader
function MenuDisabler:copyFileManagerToReader()
    UIManager:show(ConfirmBox:new{
        text = _("This will copy your File Manager menu configuration to the Reader menus.\n\nWARNING: This will override your current Reader menu settings!\n\nContinue?"),
        ok_text = _("Copy Settings"),
        cancel_text = _("Cancel"),
        ok_callback = function()
            self:performCopyFileManagerToReader()
        end,
    })
end

-- New method to perform the actual copying
function MenuDisabler:performCopyFileManagerToReader()
    local fm_filename = "filemanager_menu_order.lua"
    local reader_filename = "reader_menu_order.lua"
    
    -- Read the file manager configuration
    local fm_config = self:readMenuOrderFile(fm_filename)
    
    if not fm_config then
        UIManager:show(InfoMessage:new{
            text = _("No File Manager configuration found.\nPlease customize File Manager menus first."),
            timeout = 4,
        })
        return
    end
    
    -- Save the file manager configuration as reader configuration
    local fm_filepath = self.settings_path .. "/" .. fm_filename
    local reader_filepath = self.settings_path .. "/" .. reader_filename
    
    -- Simple file copy approach
    local success = false
    local fm_file = io.open(fm_filepath, "r")
    if fm_file then
        local content = fm_file:read("*all")
        fm_file:close()
        
        local reader_file = io.open(reader_filepath, "w")
        if reader_file then
            reader_file:write(content)
            reader_file:close()
            success = true
        end
    end
    
    if success then
        UIManager:show(InfoMessage:new{
            text = _("File Manager settings copied to Reader successfully!\n\nRestart KOReader to see changes."),
            timeout = 4,
        })
    else
        UIManager:show(InfoMessage:new{
            text = _("Error copying settings. Please try again."),
            timeout = 3,
        })
    end
end

-- Enable all menus by deleting override files
function MenuDisabler:enableAllMenus()
    local files = {"filemanager_menu_order.lua", "reader_menu_order.lua"}
    local deleted_count = 0
    
    for _, filename in ipairs(files) do
        local filepath = self.settings_path .. "/" .. filename
        if lfs.attributes(filepath, "mode") == "file" then
            local success = os.remove(filepath)
            if success then
                deleted_count = deleted_count + 1
            end
        end
    end
    
    local message = deleted_count > 0 and
        _("All menu items enabled!\n\nRestart KOReader to see changes.") or
        _("No custom menu files found.\nMenus should already be at defaults.")
    
    UIManager:show(InfoMessage:new{
        text = message,
        timeout = 3,
    })
end
return MenuDisabler
