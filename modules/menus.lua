-- Constructs and displays the menu interface, including category and item lists.
local UIManager = require("ui/uimanager")
local Menu = require("ui/widget/menu")
local Device = require("device")
local _ = require("gettext")

return function(MenuDisabler)
    function MenuDisabler:showCategoryList(selected_page)
        local menu_items = {}
    
        table.insert(menu_items, {
            text = _("* SAVE & APPLY ALL CHANGES *"),
            callback = function(dialog)
                self:closeDialogIfMatch(dialog)
                self:saveChanges()
            end,
            bold = true,
        })
    
        table.insert(menu_items, {
            text = _("--- Quick Search Menus"),
            callback = function(dialog)
                self:closeDialogIfMatch(dialog)
                self:openSearchInput()
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
                    self:closeDialogIfMatch(dialog)
                    self:showItemList(section)
                end,
            })
        end
    
        table.insert(menu_items, {
            text = _("! Reset to Defaults"),
            callback = function(dialog)
                self:closeDialogIfMatch(dialog)
                self:resetAllItems()
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
    
    function MenuDisabler:showItemList(section, select_index)
        local menu_items = {}
        local items_map = self.editing_cache.data.enabled_map[section]
    
        table.insert(menu_items, {
            text = _("SAVE CHANGES"),
            callback = function(dialog)
                self:closeDialogIfMatch(dialog)
                self:saveChanges()
            end,
            bold = true,
        })
    
        table.insert(menu_items, {
            text = _("<- Back to Categories"),
            callback = function(dialog)
                self:closeDialogIfMatch(dialog)
                self:showCategoryList()
            end,
            separator = true,
        })
    
        local items_list = {}
        for item, enabled in pairs(items_map) do
            table.insert(items_list, { name = item, enabled = enabled })
        end
        table.sort(items_list, function(a,b) return a.name < b.name end)

    -- Batch Actions: Toggle All
    local all_active = true
    local any_toggleable = false
    for _, item in ipairs(items_list) do
        local is_protected = false
        for _, p in ipairs(self.protected_items) do
            if p.section == section and p.item == item.name then is_protected = true break end
        end
        if not is_protected then
            any_toggleable = true
            if not item.enabled then all_active = false end
        end
    end

    if any_toggleable then
        local prefix = all_active and "[x] " or "[ ] "
        table.insert(menu_items, {
            text = prefix .. _("Toggle All Items"),
            bold = true,
            callback = function(dialog)
                local target = not all_active
                for _, item in ipairs(items_list) do
                    local is_protected = false
                    for _, p in ipairs(self.protected_items) do
                        if p.section == section and p.item == item.name then is_protected = true break end
                    end
                    if not is_protected then
                        self.editing_cache.data.enabled_map[section][item.name] = target
                    end
                end
                self:closeDialogIfMatch(dialog)
                self:showItemList(section)
            end,
            separator = true,
        })
    end
    
        for i, item_data in ipairs(items_list) do
            local item_name = item_data.name
            local is_enabled = item_data.enabled
            local display_name = item_name:gsub("_", " ")
    
            local is_protected = false
            for _, p in ipairs(self.protected_items) do
                if p.section == section and p.item == item_name then is_protected = true break end
            end
    
            if not is_protected then
                local prefix = is_enabled and "[x] " or "[ ] "
                table.insert(menu_items, {
                    text = prefix .. display_name,
                    callback = function(dialog)
                        self.editing_cache.data.enabled_map[section][item_name] = not self.editing_cache.data.enabled_map[section][item_name]
                        local next_index = (i + 3)
                        self:closeDialogIfMatch(dialog)
                        self:showItemList(section, next_index)
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
end
