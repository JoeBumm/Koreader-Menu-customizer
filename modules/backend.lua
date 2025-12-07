-- Handles backend logic including file I/O, data structure generation, and settings management.
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local ConfirmBox = require("ui/widget/confirmbox")
local lfs = require("libs/libkoreader-lfs")
local util = require("util")
local _ = require("gettext")

return function(MenuDisabler)
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
    
        for _, p in ipairs(self.protected_items) do
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
                            table.insert(final_disabled_list, item)
                        else
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
end
