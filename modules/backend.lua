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
    
        -- Step 1: Build enabled_map from system defaults
        local system_items = {}
        for section, items in pairs(system_struct) do
            if type(items) == "table" then
                if not section:match("^KOMenu:") then
                    sections[section] = true
                    enabled_map[section] = {}
                    for _, item in ipairs(items) do
                        if item ~= "----------------------------" then
                            enabled_map[section][item] = true
                            system_items[item] = true
                        end
                    end
                end
            end
        end
    
        -- Step 2A: Import items from user's existing config that aren't in system defaults
        -- (preserves plugin items from a previous save)
        for section, items in pairs(user_struct) do
            if type(items) == "table" and not section:match("^KOMenu:") then
                if not enabled_map[section] then
                    enabled_map[section] = {}
                    sections[section] = true
                end
                for _, item in ipairs(items) do
                    if item ~= "----------------------------" and not system_items[item] then
                        if enabled_map[section][item] == nil then
                            enabled_map[section][item] = true
                        end
                    end
                end
            end
        end
    
        -- Step 2B: Import discovered plugin items not yet in any section
        for name, info in pairs(plugins) do
            local already_present = false
            local found_in_section = nil
            for sec, items_map in pairs(enabled_map) do
                if items_map[name] ~= nil then
                    already_present = true
                    found_in_section = sec
                    break
                end
            end
            if not already_present then
                local target = "more_tools"
                if info.sorting_hint and sections[info.sorting_hint] then
                    target = info.sorting_hint
                end
                if not enabled_map[target] then
                    enabled_map[target] = {}
                    sections[target] = true
                end
                enabled_map[target][name] = true
            else
                -- Relocate items stuck in more_tools if we now know a better section
                if found_in_section == "more_tools" and info.sorting_hint and info.sorting_hint ~= "more_tools" and sections[info.sorting_hint] then
                    local was_enabled = enabled_map[found_in_section][name]
                    enabled_map[found_in_section][name] = nil
                    if not enabled_map[info.sorting_hint] then
                        enabled_map[info.sorting_hint] = {}
                        sections[info.sorting_hint] = true
                    end
                    enabled_map[info.sorting_hint][name] = was_enabled
                end
            end
        end
    
        -- Step 3: Apply disabled list from user config
        if user_struct["KOMenu:disabled"] then
            for _, disabled_item in ipairs(user_struct["KOMenu:disabled"]) do
                for section, items in pairs(enabled_map) do
                    if items[disabled_item] ~= nil then
                        enabled_map[section][disabled_item] = false
                    end
                end
            end
        end
    
        -- Step 4: Re-enable protected items
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
                                for name in c:gmatch("menu_items%.([%w_]+)%s*=") do
                                    if not plugins[name] then
                                        local hint = nil
                                        local body = c:match("menu_items%." .. name .. "%s*=%s*(%b{})")
                                        if body then
                                            hint = body:match('sorting_hint%s*=%s*"([%w_]+)"')
                                               or body:match("sorting_hint%s*=%s*'([%w_]+)'")
                                        end
                                        plugins[name] = { folder = file, sorting_hint = hint }
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        -- Also scan ./patches/ for patch files that register menu items
        local patches_path = base .. "patches"
        if lfs.attributes(patches_path, "mode") == "directory" then
            for file in lfs.dir(patches_path) do
                if file ~= "." and file ~= ".." and file:match("%.lua$") then
                    local patch_file = patches_path .. "/" .. file
                    if lfs.attributes(patch_file, "mode") == "file" then
                        local f = io.open(patch_file, "r")
                        if f then
                            local c = f:read("*all"); f:close()
                            -- Extract target section from MenuOrder references
                            local patch_section = nil
                            for section in c:gmatch("[Mm]enu[Oo]rder%.([%w_]+)") do
                                patch_section = section
                            end
                            -- Pattern 1: menu_items.name = (dot notation)
                            for name in c:gmatch("menu_items%.([%w_]+)%s*=") do
                                if not plugins[name] then
                                    plugins[name] = { folder = "patch:" .. file, sorting_hint = patch_section }
                                end
                            end
                            -- Pattern 2: menu_items["name"] or menu_items['name']
                            for name in c:gmatch('menu_items%["([%w_]+)"%]%s*=') do
                                if not plugins[name] then
                                    plugins[name] = { folder = "patch:" .. file, sorting_hint = patch_section }
                                end
                            end
                            for name in c:gmatch("menu_items%['([%w_]+)'%]%s*=") do
                                if not plugins[name] then
                                    plugins[name] = { folder = "patch:" .. file, sorting_hint = patch_section }
                                end
                            end
                            -- Pattern 3/4: table.insert into MenuOrder tables with string literal
                            for name in c:gmatch('table%.insert%([^%)]*[Mm]enu[Oo]rder[^,]*[,%s]+"([%w_]+)"') do
                                if not plugins[name] then
                                    plugins[name] = { folder = "patch:" .. file, sorting_hint = patch_section }
                                end
                            end
                            for name in c:gmatch('table%.insert%([^%)]*[Mm]enu[Oo]rder[^,]*,%s*%d+%s*,%s*"([%w_]+)"') do
                                if not plugins[name] then
                                    plugins[name] = { folder = "patch:" .. file, sorting_hint = patch_section }
                                end
                            end
                            -- Pattern 5: variable bracket notation - menu_items[var] = {...}
                            if c:match("menu_items%[%a%w*%]%s*=") then
                                for func_name in c:gmatch("local%s+function%s+(%w+)%s*%(") do
                                    for item_name in c:gmatch(func_name .. '%s*%(%s*"([%w_]+)"') do
                                        if not plugins[item_name] then
                                            plugins[item_name] = { folder = "patch:" .. file, sorting_hint = patch_section }
                                        end
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
    
    function MenuDisabler:writeOrderFile(menu_type, filename, enabled_map)
        local system_struct = self:getSystemDefaultStructure(menu_type)
    
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
        if not f then return false end
    
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
        return true
    end
    
    function MenuDisabler:saveChanges()
        if not self.editing_cache then return end
        local menu_type = self.editing_cache.type
        local filename = self.editing_cache.filename
        local enabled_map = self.editing_cache.data.enabled_map
    
        if not self:writeOrderFile(menu_type, filename, enabled_map) then
            UIManager:show(InfoMessage:new{text=_("Error writing file")})
            return
        end
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
                local ok, err = pcall(function()
                    local fm_file = self.settings_path .. "/filemanager_menu_order.lua"
                    local reader_file = self.settings_path .. "/reader_menu_order.lua"
                    if lfs.attributes(fm_file, "mode") == "file" then os.remove(fm_file) end
                    if lfs.attributes(reader_file, "mode") == "file" then os.remove(reader_file) end
                    self:safeRestart()
                end)
                if not ok then
                    UIManager:show(InfoMessage:new{text = _("Error resetting: ") .. tostring(err)})
                end
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
    
        local plugins = self:getAvailablePlugins()
    
        local output_table = {}
        local final_disabled_list = {}
        local placed_items = {}
    
        if reader_def["KOMenu:disabled"] then
            for _, item in ipairs(reader_def["KOMenu:disabled"]) do
                table.insert(final_disabled_list, item)
                placed_items[item] = true
            end
        end
    
        local known_sections = {}
        for section, items in pairs(reader_def) do
            if type(items) == "table" and not section:match("^KOMenu:") then
                known_sections[section] = true
                output_table[section] = {}
                for _, item in ipairs(items) do
                    if item == "----------------------------" then
                        table.insert(output_table[section], item)
                    else
                        placed_items[item] = true
                        if disabled_lookup[item] then
                            table.insert(final_disabled_list, item)
                        else
                            table.insert(output_table[section], item)
                        end
                    end
                end
            end
        end
    
        -- Add discovered plugin items not in reader system defaults
        for name, info in pairs(plugins) do
            if not placed_items[name] then
                placed_items[name] = true
                local target = "more_tools"
                if info.sorting_hint and known_sections[info.sorting_hint] then
                    target = info.sorting_hint
                end
                if not output_table[target] then
                    output_table[target] = {}
                    known_sections[target] = true
                end
                if disabled_lookup[name] then
                    table.insert(final_disabled_list, name)
                else
                    table.insert(output_table[target], name)
                end
            end
        end
    
        -- Import non-system items from FM config sections
        for section, items in pairs(fm_custom) do
            if type(items) == "table" and not section:match("^KOMenu:") then
                for _, item in ipairs(items) do
                    if item ~= "----------------------------" and not placed_items[item] then
                        placed_items[item] = true
                        local target = known_sections[section] and section or "more_tools"
                        if not output_table[target] then
                            output_table[target] = {}
                            known_sections[target] = true
                        end
                        if disabled_lookup[item] then
                            table.insert(final_disabled_list, item)
                        else
                            table.insert(output_table[target], item)
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
