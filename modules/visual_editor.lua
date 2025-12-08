-- Implements the Visual Editor interface, mimicking the KOReader menu structure with tabs.
local UIManager = require("ui/uimanager")
local Menu = require("ui/widget/menu")
local Device = require("device")
local _ = require("gettext")

return function(MenuDisabler)
    function MenuDisabler:showVisualEditor(active_tab_index)
        -- 1. Get the structure of tabs (sections) from the system configuration
        local system_struct = self.editing_cache.data.sections
        -- System struct in backend.lua is just a flat map of sections. 
        -- We need the ORDERED list of high-level buttons: 'KOMenu:menu_buttons'.
        
        -- To access 'KOMenu:menu_buttons', we need to look at the raw config generation.
        -- backend.lua's generateWorkingList doesn't return 'KOMenu:menu_buttons' in sections list.
        -- We need to fetch it.
        
        local menu_type = self.editing_cache.type
        local system_default = self:getSystemDefaultStructure(menu_type)
        local root_buttons = system_default["KOMenu:menu_buttons"]

        if not root_buttons then
            -- Fallback if no root structure found (shouldn't happen on standard KOReader)
            self:showCategoryList()
            return
        end

        local tabs = {}
        local tab_to_section = {}

        -- Filter out unavailable or irrelevant tabs
        for _, btn_section in ipairs(root_buttons) do
            if self.editing_cache.data.sections[btn_section] then
                table.insert(tabs, {
                    text = btn_section:gsub("_", " "):upper(),
                })
                table.insert(tab_to_section, btn_section)
            end
        end

        -- Add an "Extra" tab for orphan sections not in the main menu (if any)
        local covered_sections = {}
        for _, s in ipairs(tab_to_section) do covered_sections[s] = true end
        
        -- Also check for typical orphan sections we might want to group
        -- For now, lets stick to the main tabs + a "Save/Exit" tab.
        
        table.insert(tabs, { text = _("ACTIONS") })
        
        if not active_tab_index then active_tab_index = 1 end

        -- 2. Build items for the active tab
        local menu_items = {}
        
        if active_tab_index <= #tab_to_section then
            local current_section = tab_to_section[active_tab_index]
            local items_map = self.editing_cache.data.enabled_map[current_section]
            
            -- Sort items alphabetically
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
                for _, p in ipairs(self.protected_items) do
                    if p.section == current_section and p.item == item_name then is_protected = true break end
                end

                if not is_protected then
                    local prefix = is_enabled and "[x] " or "[ ] " -- In a real visual editor we might use icons, but text is safe.
                    local suffix = is_enabled and "" or " (OFF)"
                    
                    table.insert(menu_items, {
                        text = display_name .. suffix,
                        checked = is_enabled, -- Menu widget supports 'checked' property often rendered as a checkmark/dot
                        callback = function(dialog)
                            self.editing_cache.data.enabled_map[current_section][item_name] = not self.editing_cache.data.enabled_map[current_section][item_name]
                            self:closeDialogIfMatch(dialog)
                            self:showVisualEditor(active_tab_index) -- Reload w/ same tab
                        end,
                    })
                else
                    table.insert(menu_items, {
                        text = "🔒 " .. display_name .. " (Required)",
                        enabled = false,
                    })
                end
            end
        else
            -- Actions Tab
            table.insert(menu_items, {
                text = _("💾 Save & Apply Changes"),
                callback = function(dialog)
                    self:closeDialogIfMatch(dialog)
                    self:saveChanges()
                end,
                bold = true,
            })
            table.insert(menu_items, {
                text = _("🔍 Search for an Item"),
                callback = function(dialog)
                    self:closeDialogIfMatch(dialog)
                    self:openSearchInput()
                end,
            })
            table.insert(menu_items, {
                text = _("⚠️ Reset to Defaults"),
                callback = function(dialog)
                    self:closeDialogIfMatch(dialog)
                    self:resetAllItems()
                end,
                separator = true,
            })
             table.insert(menu_items, {
                text = _("❌ Cancel / Exit"),
                callback = function(dialog)
                    self:closeDialogIfMatch(dialog)
                end,
            })
        end

        local dlg = Menu:new{
            title = _("Visual Editor: ") .. self.editing_cache.type:upper(),
            item_table = menu_items,
            tab_table = tabs,
            active_tab = active_tab_index,
            on_tab_change = function(new_tab_idx)
                self:closeDialogIfMatch(self.active_dialog)
                self:showVisualEditor(new_tab_idx)
            end,
            width = Device.screen:getWidth(),
            height = Device.screen:getHeight(),
            -- Reduce borders to make it feel more full-screen?
            -- show_parent = self, -- maybe?
        }
        self:showDialog(dlg)
    end
end
