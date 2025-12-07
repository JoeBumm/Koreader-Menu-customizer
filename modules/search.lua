-- Implements search functionality for finding specific menu items.
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local InputDialog = require("ui/widget/inputdialog")
local Menu = require("ui/widget/menu")
local Device = require("device")
local _ = require("gettext")

return function(MenuDisabler)
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
                        self:showSearchResults(q)
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
end
