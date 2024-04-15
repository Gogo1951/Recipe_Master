local _, rm = ...
local L = rm.L

local function isItemRecipe(itemName)
    for _, prefix in pairs(L.recipePrefixes) do
        if itemName:sub(1, #prefix) == prefix then
            return true
        end
    end
    return false
end

local function getRecipeTooltipMessage(recipe, profession)
    local charactersMissingRecipeSkill, charactersWithRecipeSkill = rm.getAllCharactersRecipeStatus(recipe, profession)
    local message = ""
    local newLine = "\n"
    local newLineInfo = "\n    "
    if #charactersWithRecipeSkill > 0 then
        message = message..newLine..WrapTextInColorCode(L.crafters, "FF90EE90") -- Light green
        for _, character in pairs(charactersWithRecipeSkill) do
            message = message..newLineInfo..character
        end
    end
    if #charactersMissingRecipeSkill > 0 then
        message = message..newLine..WrapTextInColorCode(L.missing, "FFFFB6C1") -- Light red
        for _, character in pairs(charactersMissingRecipeSkill) do
            message = message..newLineInfo..character
        end
    end
    return rm.L.title..WrapTextInColorCode(message, "FFFFFFFF") -- White
end

-- Ensures that the message is not displayed twice
local function isTooltipMessageDisplayed(i, tooltip, message)
    return string.find(_G[tooltip:GetName().."TextLeft"..i]:GetText(), message)
end

local function showTooltipMessage(tooltip, message)
    for i = 1, tooltip:NumLines() do
        if isTooltipMessageDisplayed(i, tooltip, message) then
            return
        end
    end
    tooltip:AddLine("\n"..message.."\n")
end

-- Appends the message to a recipe's tooltip
GameTooltip:HookScript("OnTooltipSetItem", function(tooltip, ...)
    local itemName, itemLink = tooltip:GetItem()
    if itemName and isItemRecipe(itemName) then
        local recipeID = rm.getIdFromItemLink(itemLink)
        local professionName = select(7, C_Item.GetItemInfo(itemLink))
        professionName = rm.handleMismatchedProfessionNames(professionName)
        local professionID = rm.getProfessionID(professionName)
        local recipe = rm.recipes[professionID][recipeID]
        local message = getRecipeTooltipMessage(recipe, professionID)
        local messageLineCount = select(2, message:gsub("\n", "\n"))
        if messageLineCount > 0 then -- Not counting the "Recipe Master" header
            showTooltipMessage(tooltip, message)
        end
    end
end)