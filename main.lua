local WidgetContainer = require("ui/widget/container/widgetcontainer")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local ConfirmBox = require("ui/widget/confirmbox")
local InputDialog = require("ui/widget/inputdialog")
local Menu = require("ui/widget/menu")
local Device = require("device")
local lfs = require("libs/libkoreader-lfs")
local util = require("util")
local logger = require("logger")
local _ = require("gettext")

require("ui/plugin/insert_menu").add("menu_disabler")

local MenuDisabler = WidgetContainer:extend{
    is_doc_only = false,
    settings_path = require("datastorage"):getSettingsDir(),
    editing_cache = nil,
    active_dialog = nil,
    profiles_file = "menu_disabler_profiles.lua",
}

local protected_items = {
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

function MenuDisabler:safeExecute(func)
    local status, err = xpcall(func, debug.traceback)
    if not status then
        logger.err("MenuDisabler Safety Catch: " .. tostring(err))
        UIManager:show(InfoMessage:new{
            text = _("Plugin Error (Crash Prevented):\n") .. tostring(err):match("^(.-)\n"),
            timeout = 5,
        })
    end
end

function MenuDisabler:init()
    self.ui.menu:registerToMainMenu(self)
end

function MenuDisabler:addToMainMenu(menu_items)
    local is_doc_open = self.ui.document ~= nil

    menu_items.menu_disabler = {
        text = _("Menu Disabler"),
        sub_item_table = {
            {
                text = _("Customize File Manager Menus"),
                callback = function() self:safeExecute(function() self:initSession("filemanager") end) end,
            },
            {
                text = is_doc_open and _("Customize Reader Menus (Close book first)") or _("Customize Reader Menus"),
                enabled = not is_doc_open,
                callback = function()
                    self:safeExecute(function()
                        if is_doc_open then
                            UIManager:show(InfoMessage:new{
                                text = _("To prevent instability, please close the current book before editing Reader menus."),
                                timeout = 4
                            })
                        else
                            self:initSession("reader")
                        end
                    end)
                end
            },
            {
                text = is_doc_open and _("Profiles (Save/Load/Delete) (Close book first)") or _("Profiles (Save/Load/Delete)"),
                enabled = not is_doc_open,
                sub_item_table_func = function()
                    local items = {}
                    self:safeExecute(function() items = self:getProfilesMenu() end)
                    return items
                end,
                separator = true,
            },
            {
                text = _("Apply File Manager Layout to Reader"),
                callback = function() self:safeExecute(function() self:copySettings() end) end
            },
            {
                text = _("Reset All Menus to Default"),
                callback = function() self:safeExecute(function() self:confirmResetEverything() end) end
            }
        }
    }
end

-- ===== Helper: centralized show/close for dialogs =====
function MenuDisabler:showDialog(dialog)
    if self.active_dialog and self.active_dialog ~= dialog then
        pcall(function() UIManager:close(self.active_dialog) end)
        self.active_dialog = nil
    end

    local orig_close = dialog.close_callback
    dialog.close_callback = function(...)
        if type(orig_close) == "function" then pcall(orig_close, ...) end
        if self.active_dialog == dialog then self.active_dialog = nil end
    end

    self.active_dialog = dialog
    UIManager:show(dialog)
end

function MenuDisabler:closeDialogIfMatch(dialog)
    if dialog and self.active_dialog == dialog then
        UIManager:close(dialog)
        self.active_dialog = nil
    end
end

-- ===== Entry point for editing session =====
function MenuDisabler:initSession(menu_type)
    if self.active_dialog then
        pcall(function() UIManager:close(self.active_dialog) end)
        self.active_dialog = nil
    end

    local filename = menu_type .. "_menu_order.lua"
    self.editing_cache = {
        type = menu_type,
        filename = filename,
        data = self:generateWorkingList(menu_type, filename)
    }
    self:showCategoryList()
end

-- ===== Full-screen Category List =====
function MenuDisabler:showCategoryList(selected_page)
    local menu_items = {}

    table.insert(menu_items, {
        text = _("* SAVE & APPLY ALL CHANGES *"),
        callback = function(dialog)
            self:safeExecute(function()
                self:closeDialogIfMatch(dialog)
                self:saveChanges()
            end)
        end,
        bold = true,
    })

    table.insert(menu_items, {
        text = _("--- Quick Search Menus"),
        callback = function(dialog)
            self:safeExecute(function()
                self:closeDialogIfMatch(dialog)
                self:openSearchInput()
            end)
        end,
    })

    local sorted_sections = {}
    for section in pairs(self.editing_cache.data.sections) do
        table.insert(sorted_sections, section)
    end
    table.sort(sorted_sections)

    for _, section in ipairs(sorted_sections) do
        local total, enabled_count = 0, 0
        for _, enabled in pairs(self.editing_cache.data.enabled_map[section]) do
            total = total + 1
            if enabled then enabled_count = enabled_count + 1 end
        end

        table.insert(menu_items, {
            text = "» " .. section:gsub("_", " "):upper() .. string.format(" (%d/%d)", enabled_count, total),
            callback = function(dialog)
                self:safeExecute(function()
                    self:closeDialogIfMatch(dialog)
                    self:showItemList(section)
                end)
            end,
        })
    end

    table.insert(menu_items, {
        text = _("! Reset to Defaults"),
        callback = function(dialog)
            self:safeExecute(function()
                self:closeDialogIfMatch(dialog)
                self:resetAllItems()
            end)
        end,
        separator = true,
    })

    local dlg = Menu:new{
        title = _("Menu Disabler: ") .. self.editing_cache.type:upper(),
        item_table = menu_items,
        page = selected_page,
        width = Device.screen:getWidth(),
        height = Device.screen:getHeight(),
    }
    self:showDialog(dlg)
end

-- ===== Full-screen Item List =====
function MenuDisabler:showItemList(section, select_index)
    local menu_items = {}
    local items_map = self.editing_cache.data.enabled_map[section]

    table.insert(menu_items, {
        text = _("SAVE CHANGES"),
        callback = function(dialog)
            self:safeExecute(function()
                self:closeDialogIfMatch(dialog)
                self:saveChanges()
            end)
        end,
        bold = true,
    })

    table.insert(menu_items, {
        text = _("<- Back to Categories"),
        callback = function(dialog)
            self:safeExecute(function()
                self:closeDialogIfMatch(dialog)
                self:showCategoryList()
            end)
        end,
        separator = true,
    })

    local items_list = {}
    for item, enabled in pairs(items_map) do
        table.insert(items_list, { name = item, enabled = enabled })
    end
    table.sort(items_list, function(a,b) return a.name < b.name end)

    for i, item_data in ipairs(items_list) do
        local item_name = item_data.name
        local is_enabled = item_data.enabled
        local display_name = item_name:gsub("_", " ")

        local is_protected = false
        for _, p in ipairs(protected_items) do
            if p.section == section and p.item == item_name then is_protected = true break end
        end

        if not is_protected then
            local prefix = is_enabled and "[x] " or "[ ] "
            table.insert(menu_items, {
                text = prefix .. display_name,
                callback = function(dialog)
                    self:safeExecute(function()
                        self.editing_cache.data.enabled_map[section][item_name] = not self.editing_cache.data.enabled_map[section][item_name]
                        local next_index = (i + 3)
                        self:closeDialogIfMatch(dialog)
                        self:showItemList(section, next_index)
                    end)
                end,
            })
        else
            table.insert(menu_items, {
                text = "[!] " .. display_name .. " (Required)",
                enabled = false,
            })
        end
    end

    local dlg = Menu:new{
        title = _("Editing: ") .. section:upper(),
        item_table = menu_items,
        select_item = select_index,
        width = Device.screen:getWidth(),
        height = Device.screen:getHeight(),
    }
    self:showDialog(dlg)
end

-- ===== Search UI & Logic =====
function MenuDisabler:openSearchInput()
    local input
    input = InputDialog:new{
        title = _("Search menu items"),
        input_type = "text",
        buttons = {{
            { text = _("Cancel"), callback = function() UIManager:close(input) end },
            { text = _("Search"), callback = function()
                local q = input:getInputText()
                UIManager:close(input)
                if q and q:match("%S") then
                    self:safeExecute(function() self:showSearchResults(q) end)
                else
                    UIManager:show(InfoMessage:new{text=_("Empty query")})
                end
            end }
        }}
    }
    self:showDialog(input)
    input:onShowKeyboard()
end

function MenuDisabler:showSearchResults(query)
    query = query:lower()
    local results = {}

    for section, items in pairs(self.editing_cache.data.enabled_map) do
        for item_name, enabled in pairs(items) do
            local combine = section .. " " .. item_name
            if combine:lower():find(query, 1, true) then
                table.insert(results, {
                    section = section,
                    item = item_name,
                    enabled = enabled,
                })
            end
        end
    end

    if #results == 0 then
        UIManager:show(InfoMessage:new{text = _("No matches")})
        return
    end

    local menu_items = {}
    for _, r in ipairs(results) do
        local disp = string.format("%s / %s %s", r.section, r.item:gsub("_"," "), r.enabled and "(on)" or "(off)")
        table.insert(menu_items, {
            text = disp,
            callback = function(dialog)
                self:safeExecute(function()
                    self:closeDialogIfMatch(dialog)
                    local idx = nil
                    local map = self.editing_cache.data.enabled_map[r.section]
                    local list = {}
                    for nm, st in pairs(map) do table.insert(list, nm) end
                    table.sort(list)
                    for i, nm in ipairs(list) do
                        if nm == r.item then idx = i; break end
                    end
                    self:showItemList(r.section, (idx and idx+3) or 1)
                end)
            end
        })
    end

    local dlg = Menu:new{
        title = _("Search results for: ") .. query,
        item_table = menu_items,
        width = Device.screen:getWidth(),
        height = Device.screen:getHeight(),
    }
    self:showDialog(dlg)
end

-- ===== Backend =====
function MenuDisabler:generateWorkingList(menu_type, filename)
    local system_struct = self:getSystemDefaultStructure(menu_type)
    local user_struct = self:getUserCustomStructure(filename) or {}
    local plugins = self:getAvailablePlugins()

    local enabled_map = {}
    local sections = {}

    for section, items in pairs(system_struct) do
        if type(items) == "table" then
            if not section:match("^KOMenu:") then
                sections[section] = true
                enabled_map[section] = {}
                for _, item in ipairs(items) do
                    if item ~= "----------------------------" then
                        enabled_map[section][item] = true
                    end
                end
            end
        end
    end

    if user_struct["KOMenu:disabled"] then
        for _, disabled_item in ipairs(user_struct["KOMenu:disabled"]) do
            for section, items in pairs(enabled_map) do
                if items[disabled_item] ~= nil then
                    enabled_map[section][disabled_item] = false
                end
            end
        end
    end

    for _, p in ipairs(protected_items) do
        if enabled_map[p.section] then
            enabled_map[p.section][p.item] = true
        end
    end

    return { enabled_map = enabled_map, sections = sections }
end

function MenuDisabler:getSystemDefaultStructure(menu_type)
    local filename = (menu_type == "filemanager") and "filemanager_menu_order.lua" or "reader_menu_order.lua"
    local paths = { "frontend/ui/elements/" .. filename, "ui/elements/" .. filename, "common/ui/elements/" .. filename }
    for _, path in ipairs(paths) do
        if lfs.attributes(path, "mode") == "file" then
            local chunk = loadfile(path)
            if chunk then
                local ok, res = pcall(chunk)
                if ok and type(res) == "table" then return util.tableDeepCopy(res) end
            end
        end
    end
    local req_path = "ui/elements/" .. (menu_type == "filemanager" and "filemanager_menu_order" or "reader_menu_order")
    local ok, res = pcall(require, req_path)
    if ok and type(res) == "table" then return util.tableDeepCopy(res) end
    return {}
end

function MenuDisabler:getUserCustomStructure(filename)
    local filepath = self.settings_path .. "/" .. filename
    if lfs.attributes(filepath, "mode") == "file" then
        local chunk = loadfile(filepath)
        if chunk then
            local ok, res = pcall(chunk)
            if ok and type(res) == "table" then return res end
        end
    end
    return nil
end

function MenuDisabler:getAvailablePlugins()
    local plugins = {}
    local base = self.settings_path:gsub("settings/?$", "")
    local paths = { base .. "plugins", base .. "plugins/patch" }
    for _, path in ipairs(paths) do
        if lfs.attributes(path, "mode") == "directory" then
            for file in lfs.dir(path) do
                if file ~= "." and file ~= ".." then
                    local main_file = path .. "/" .. file .. "/main.lua"
                    if lfs.attributes(main_file, "mode") == "file" then
                        local f = io.open(main_file, "r")
                        if f then
                            local c = f:read("*all"); f:close()
                            local name = c:match("menu_items%.([%w_]+)%s*=")
                            if name then plugins[name] = file end
                        end
                    end
                end
            end
        end
    end
    return plugins
end

-- ===== Profiles system=====
function MenuDisabler:getProfilesMenu()
    local menu_items = {}

    table.insert(menu_items, {
        text = _("[+] Save Current Setup as New Profile"),
        callback = function(dialog) self:safeExecute(function() self:closeDialogIfMatch(dialog); self:promptCreateProfile() end) end,
        bold = true,
        separator = true,
    })

    local profiles = self:loadProfilesFromDisk()
    local sorted_names = {}
    for name, _ in pairs(profiles) do table.insert(sorted_names, name) end
    table.sort(sorted_names)

    if #sorted_names > 0 then
        table.insert(menu_items, { text = _("--- Load Profile ---"), enabled = false })
        for _, name in ipairs(sorted_names) do
            table.insert(menu_items, {
                text = " > " .. name,
                callback = function(dialog) self:safeExecute(function() self:closeDialogIfMatch(dialog); self:applyProfile(name, profiles[name]) end) end,
            })
        end

        table.insert(menu_items, { text = _("--- Manage ---"), enabled = false })
        table.insert(menu_items, {
            text = _("Delete a Profile"),
            sub_item_table_func = function()
                local del_items = {}
                for _, name in ipairs(sorted_names) do
                    table.insert(del_items, {
                        text = "[x] " .. name,
                        callback = function(dialog) self:safeExecute(function() self:closeDialogIfMatch(dialog); self:deleteProfile(name) end) end
                    })
                end
                return del_items
            end
        })
    else
        table.insert(menu_items, { text = _("(No saved profiles yet)"), enabled = false })
    end
    return menu_items
end

function MenuDisabler:loadProfilesFromDisk()
    local path = self.settings_path .. "/" .. self.profiles_file
    if lfs.attributes(path, "mode") == "file" then
        local chunk = loadfile(path)
        if chunk then
            local ok, res = pcall(chunk)
            if ok and type(res) == "table" then return res end
        end
    end
    return {}
end

function MenuDisabler:saveProfilesToDisk(profiles)
    local f = io.open(self.settings_path .. "/" .. self.profiles_file, "w")
    if not f then return false end
    f:write("return {\n")
    for name, data in pairs(profiles) do
        f:write(string.format("    [%q] = {\n", name))
        if data.fm then f:write(string.format("        fm = %q,\n", data.fm)) end
        if data.reader then f:write(string.format("        reader = %q,\n", data.reader)) end
        f:write("    },\n")
    end
    f:write("}\n")
    f:close()
    return true
end

function MenuDisabler:promptCreateProfile()
    local fm = self:getUserCustomStructure("filemanager_menu_order.lua")
    local rd = self:getUserCustomStructure("reader_menu_order.lua")
    if not fm and not rd then UIManager:show(InfoMessage:new{text=_("No settings to save!")}) return end

    local input
    input = InputDialog:new{
        title = _("Name this Profile"),
        input_type = "text",
        buttons = {{
            { text = _("Cancel"), callback = function() UIManager:close(input) end },
            { text = _("Save"), callback = function()
                local name = input:getInputText()
                if name and name ~= "" then
                    UIManager:close(input)
                    self:safeExecute(function()
                        local f1 = io.open(self.settings_path.."/filemanager_menu_order.lua", "r")
                        local c1 = f1 and f1:read("*all"); if f1 then f1:close() end
                        local f2 = io.open(self.settings_path.."/reader_menu_order.lua", "r")
                        local c2 = f2 and f2:read("*all"); if f2 then f2:close() end

                        local profiles = self:loadProfilesFromDisk()
                        profiles[name] = { fm = c1, reader = c2 }
                        self:saveProfilesToDisk(profiles)
                        UIManager:show(InfoMessage:new{text=_("Saved: ")..name})
                    end)
                end
            end }
        }}
    }
    self:showDialog(input)
    input:onShowKeyboard()
end

function MenuDisabler:applyProfile(name, data)
    UIManager:show(ConfirmBox:new{
        text = _("Load profile '") .. name .. _("'?"),
        ok_text = _("Load"),
        cancel_text = _("Cancel"),
        ok_callback = function()
            self:safeExecute(function()
                local f1 = self.settings_path.."/filemanager_menu_order.lua"
                if data.fm then local f=io.open(f1,"w"); f:write(data.fm); f:close() else os.remove(f1) end
                local f2 = self.settings_path.."/reader_menu_order.lua"
                if data.reader then local f=io.open(f2,"w"); f:write(data.reader); f:close() else os.remove(f2) end
                self:safeRestart()
            end)
        end
    })
end

function MenuDisabler:deleteProfile(name)
    UIManager:show(ConfirmBox:new{
        text = _("Delete profile '") .. name .. _("'?"),
        ok_text = _("Delete"),
        cancel_text = _("Cancel"),
        ok_callback = function()
            self:safeExecute(function()
                local profiles = self:loadProfilesFromDisk()
                profiles[name] = nil
                self:saveProfilesToDisk(profiles)
                UIManager:show(InfoMessage:new{text=_("Deleted")})
            end)
        end
    })
end

-- ===== Saving & actions =====
function MenuDisabler:saveChanges()
    if not self.editing_cache then return end
    local menu_type = self.editing_cache.type
    local filename = self.editing_cache.filename
    local system_struct = self:getSystemDefaultStructure(menu_type)
    local enabled_map = self.editing_cache.data.enabled_map

    local disabled_list = {}
    local output_table = {}

    for key, val in pairs(system_struct) do
        if key:match("^KOMenu:") and key ~= "KOMenu:disabled" then
            output_table[key] = util.tableDeepCopy(val)
        end
    end

    for section, items in pairs(system_struct) do
        if not section:match("^KOMenu:") then
            output_table[section] = {}
            for _, item in ipairs(items) do
                if item == "----------------------------" then
                    table.insert(output_table[section], item)
                else
                    if enabled_map[section] and enabled_map[section][item] then
                        table.insert(output_table[section], item)
                    else
                        table.insert(disabled_list, item)
                    end
                end
            end
        end
    end

    for section, items_map in pairs(enabled_map) do
        if not output_table[section] then output_table[section] = {} end
        for item_name, enabled in pairs(items_map) do
            local exists = false
            for _, v in ipairs(output_table[section]) do if v == item_name then exists = true break end end
            if not exists then
                if enabled then table.insert(output_table[section], item_name)
                else
                    local is_dis = false
                    for _, d in ipairs(disabled_list) do if d == item_name then is_dis = true break end end
                    if not is_dis then table.insert(disabled_list, item_name) end
                end
            end
        end
    end

    output_table["KOMenu:disabled"] = disabled_list

    local f = io.open(self.settings_path .. "/" .. filename, "w")
    if not f then UIManager:show(InfoMessage:new{text=_("Error writing file")}) return end

    f:write("return {\n")
    for key, val in pairs(output_table) do
        if key:match("^KOMenu:") then
            f:write("    [\"" .. key .. "\"] = {\n")
            for _, v in ipairs(val) do f:write("        \"" .. v .. "\",\n") end
            f:write("    },\n")
        end
    end

    for key, val in pairs(output_table) do
        if not key:match("^KOMenu:") then
            f:write("    [\"" .. key .. "\"] = {\n")
            for _, v in ipairs(val) do f:write("        \"" .. v .. "\",\n") end
            -- FIXED: Added closing brace for table
            f:write("    },\n")
        end
    end

    f:write("}\n")
    f:close()

    self:safeRestart()
end

function MenuDisabler:resetAllItems()
    if not self.editing_cache then return end
    os.remove(self.settings_path .. "/" .. self.editing_cache.filename)
    self.editing_cache = nil
    self:safeRestart()
end

function MenuDisabler:confirmResetEverything()
    UIManager:show(ConfirmBox:new{
        text = _("Reset ALL menus to default?"),
        ok_text = _("Reset"),
        cancel_text = _("Cancel"),
        ok_callback = function()
            self:safeExecute(function()
                local fm_file = self.settings_path .. "/filemanager_menu_order.lua"
                local reader_file = self.settings_path .. "/reader_menu_order.lua"
                if lfs.attributes(fm_file, "mode") == "file" then os.remove(fm_file) end
                if lfs.attributes(reader_file, "mode") == "file" then os.remove(reader_file) end
                self:safeRestart()
            end)
        end
    })
end

function MenuDisabler:copySettings()
    local fm_custom = self:getUserCustomStructure("filemanager_menu_order.lua")
    if not fm_custom or not fm_custom["KOMenu:disabled"] then
        UIManager:show(InfoMessage:new{text=_("No disabled items in File Manager to copy.")})
        return
    end
    local disabled_items = fm_custom["KOMenu:disabled"]
    local disabled_lookup = {}
    for _, item in ipairs(disabled_items) do disabled_lookup[item] = true end

    local reader_def = self:getSystemDefaultStructure("reader")
    if not reader_def or next(reader_def) == nil then
        UIManager:show(InfoMessage:new{text=_("Error: Could not load Reader defaults.")})
        return
    end

    local output_table = {}
    local final_disabled_list = {}

    if reader_def["KOMenu:disabled"] then
        for _, item in ipairs(reader_def["KOMenu:disabled"]) do
            table.insert(final_disabled_list, item)
        end
    end

    for section, items in pairs(reader_def) do
        if type(items) == "table" and not section:match("^KOMenu:") then
            output_table[section] = {}
            for _, item in ipairs(items) do
                if item == "----------------------------" then
                    table.insert(output_table[section], item)
                else
                    if disabled_lookup[item] then
                        -- Disable it
                        table.insert(final_disabled_list, item)
                    else
                        -- Keep it active
                        table.insert(output_table[section], item)
                    end
                end
            end
        end
    end

    output_table["KOMenu:disabled"] = final_disabled_list

    if reader_def["KOMenu:menu_buttons"] then
        output_table["KOMenu:menu_buttons"] = util.tableDeepCopy(reader_def["KOMenu:menu_buttons"])
    end

    local dst_path = self.settings_path .. "/reader_menu_order.lua"
    local f = io.open(dst_path, "w")
    if not f then
        UIManager:show(InfoMessage:new{text=_("Error writing file")})
        return
    end

    f:write("return {\n")
    for key, val in pairs(output_table) do
        if key:match("^KOMenu:") then
            f:write("    [\"" .. key .. "\"] = {\n")
            for _, v in ipairs(val) do f:write("        \"" .. v .. "\",\n") end
            f:write("    },\n")
        end
    end
    for key, val in pairs(output_table) do
        if not key:match("^KOMenu:") then
            f:write("    [\"" .. key .. "\"] = {\n")
            for _, v in ipairs(val) do f:write("        \"" .. v .. "\",\n") end
            -- FIXED: Added closing brace for table
            f:write("    },\n")
        end
    end
    f:write("}\n")
    f:close()

    self:safeRestart()
end

function MenuDisabler:safeRestart()
    UIManager:show(ConfirmBox:new{
        text = _("Settings saved!\n\nPlease restart KOReader manually."),
        ok_text = _("OK"),
    })
end
return MenuDisabler
