-- Entry point for the Menu Disabler plugin. Initializes the plugin and loads all modules.
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local _ = require("gettext")

require("ui/plugin/insert_menu").add("menu_disabler")

local MenuDisabler = WidgetContainer:extend{
    is_doc_only = false,
    settings_path = require("datastorage"):getSettingsDir(),
    editing_cache = nil,
    active_dialog = nil,
    profiles_file = "menu_disabler_profiles.lua",
}

local modules_path = "user.plugins.menu_disabler.koplugin.modules."

local function load_module(name)
    local path = debug.getinfo(1).source:match("@?(.*[\\/])")
    local f = assert(loadfile(path .. "modules/" .. name .. ".lua"))
    return f()
end

load_module("constants")(MenuDisabler)
load_module("backend")(MenuDisabler)
load_module("profiles")(MenuDisabler)
load_module("search")(MenuDisabler)
load_module("menus")(MenuDisabler)

function MenuDisabler:init()
    self.ui.menu:registerToMainMenu(self)
end

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

function MenuDisabler:addToMainMenu(menu_items)
    local is_doc_open = self.ui.document ~= nil

    menu_items.menu_disabler = {
        text = _("Menu Disabler"),
        sub_item_table = {
            {
                text = _("Customize File Manager Menus"),
                callback = function() self:initSession("filemanager") end,
            },
            {
                text = is_doc_open and _("Customize Reader Menus (Close book first)") or _("Customize Reader Menus"),
                enabled = not is_doc_open,
                callback = function()
                    if is_doc_open then
                        UIManager:show(InfoMessage:new{
                            text = _("To prevent instability, please close the current book before editing Reader menus."),
                            timeout = 4
                        })
                    else
                        self:initSession("reader")
                    end
                end
            },
            {
                text = is_doc_open and _("Profiles (Save/Load/Delete) (Close book first)") or _("Profiles (Save/Load/Delete)"),
                enabled = not is_doc_open,
                sub_item_table_func = function()
                    return self:getProfilesMenu()
                end,
                separator = true,
            },
            {
                text = _("Apply File Manager Layout to Reader"),
                callback = function() self:copySettings() end
            },
            {
                text = _("Reset All Menus to Default"),
                callback = function() self:confirmResetEverything() end
            }
        }
    }
end

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

return MenuDisabler
