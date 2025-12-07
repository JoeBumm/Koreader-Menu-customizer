-- Manages plugin profiles, including saving, loading, and deleting configurations.
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local ConfirmBox = require("ui/widget/confirmbox")
local InputDialog = require("ui/widget/inputdialog")
local lfs = require("libs/libkoreader-lfs")
local _ = require("gettext")

return function(MenuDisabler)
    function MenuDisabler:getProfilesMenu()
        local menu_items = {}
    
        table.insert(menu_items, {
            text = _("[+] Save Current Setup as New Profile"),
            callback = function(dialog) self:closeDialogIfMatch(dialog); self:promptCreateProfile() end,
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
                    callback = function(dialog) self:closeDialogIfMatch(dialog); self:applyProfile(name, profiles[name]) end,
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
                            callback = function(dialog) self:closeDialogIfMatch(dialog); self:deleteProfile(name) end
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
                        local f1 = io.open(self.settings_path.."/filemanager_menu_order.lua", "r")
                        local c1 = f1 and f1:read("*all"); if f1 then f1:close() end
                        local f2 = io.open(self.settings_path.."/reader_menu_order.lua", "r")
                        local c2 = f2 and f2:read("*all"); if f2 then f2:close() end

                        local profiles = self:loadProfilesFromDisk()
                        profiles[name] = { fm = c1, reader = c2 }
                        self:saveProfilesToDisk(profiles)
                        UIManager:show(InfoMessage:new{text=_("Saved: ")..name})
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
                local f1 = self.settings_path.."/filemanager_menu_order.lua"
                if data.fm then local f=io.open(f1,"w"); f:write(data.fm); f:close() else os.remove(f1) end
                local f2 = self.settings_path.."/reader_menu_order.lua"
                if data.reader then local f=io.open(f2,"w"); f:write(data.reader); f:close() else os.remove(f2) end
                self:safeRestart()
            end
        })
    end
    
    function MenuDisabler:deleteProfile(name)
        UIManager:show(ConfirmBox:new{
            text = _("Delete profile '") .. name .. _("'?"),
            ok_text = _("Delete"),
            cancel_text = _("Cancel"),
            ok_callback = function()
                local profiles = self:loadProfilesFromDisk()
                profiles[name] = nil
                self:saveProfilesToDisk(profiles)
                UIManager:show(InfoMessage:new{text=_("Deleted")})
            end
        })
    end
end
