local _, rm = ...
local L = rm.L

local function isRecipeForCurrentSeason(recipe)
    local serverSeason = rm.getSeason()
    return not recipe.season or (recipe.season == serverSeason)
end

local function isRecipeForCurrentClass(recipe)
    local _, characterClass = UnitClass("player") -- Always in English and upper case
    return not recipe.class or (string.upper(recipe.class) == characterClass)
end

local function isRecipeForCurrentSpecialization(recipe)
    local professionID = rm.getProfessionID(rm.displayedProfession)
    local currentSpecialization = rm.getSavedSpecializationByID(professionID)
    return (
        not recipe.specialization 
        or not currentSpecialization 
        or (currentSpecialization == recipe.specialization)
    )
end

function rm.isRecipeAvailableForCharacter(recipe)
    return (
        isRecipeForCurrentSeason(recipe) 
        and isRecipeForCurrentClass(recipe) 
        and isRecipeForCurrentSpecialization(recipe)
    )
end

local function isRankupRecipe(recipe)
    return type(recipe.teachesSpell) == "string"
end

local function isSkillLearnedByCharacter(characterSkills, recipe)
    return (
        rm.tableContains(characterSkills, recipe.teachesItem)
        or rm.tableContains(characterSkills, recipe.teachesSpell)
    )
end

function rm.getAllCharactersRecipeStatus(recipe, professionID)
    local characters = rm.getProfessionSkillsForAllCharacters(professionID)
    local charactersMissingRecipeSkill = {}
    local charactersWithRecipeSkill = {}
    for character in pairs(characters) do
        local characterSkills = characters[character][professionID]
        if character ~= rm.currentCharacter and not isRankupRecipe(recipe) and characterSkills then
            if not isSkillLearnedByCharacter(characterSkills, recipe) then
                table.insert(charactersMissingRecipeSkill, character)
            else
                table.insert(charactersWithRecipeSkill, character)
            end
        end
    end
    return charactersMissingRecipeSkill, charactersWithRecipeSkill
end

-- Identifies all rankup recipes that teach a rank equal to or lower than the current profession rank
local function isLearnedRankupRecipe(recipe, professionRank)
    if isRankupRecipe(recipe) then
        local rankOrder = {Apprentice = 1, Journeyman = 2, Expert = 3, Artisan = 4}
        return rankOrder[recipe.teachesSpell] <= rankOrder[professionRank]
    end
    return false
end

function rm.isLearnedRecipe(recipe)
    local learnedSkills = rm.getSavedSkillsByProfessionName(rm.displayedProfession)
    local professionRank = rm.getSavedProfessionRank(rm.displayedProfession)
    local isLearnedRecipe = isSkillLearnedByCharacter(learnedSkills, recipe)
    return isLearnedRecipe or isLearnedRankupRecipe(recipe, professionRank)
end

function rm.isMissingRecipeOfCurrentFaction(recipe)
    local characterFaction = rm.currentFaction
    return not recipe.faction or (recipe.faction == characterFaction)
end

local function isMiningSkill(recipeID)
    return recipeID == 14891 or recipeID == 22967
end

local function getAdditionalRecipeData(ID)
    local name, link, quality, _, _, _, _, _, _, texture = C_Item.GetItemInfo(ID)
    if isMiningSkill(ID) then
        name = GetSpellInfo(ID)
        link = "|cff71d5ff|Hspell:"..ID.."|h["..name.."]|h|r"
        texture = rm.recipeDB[186][ID].icon
    end
    return rm.removeRecipePrefix(name, true), link, quality, texture
end

local function saveRecipeData(recipeID, recipeData)
    local rName, rLink, rQuality, rTexture = getAdditionalRecipeData(recipeID)
    return {
        class = recipeData["class"], 
        faction = recipeData["faction"], 
        link = rLink,
        name = rName, 
        quality = rQuality, 
        repFaction = recipeData["repFaction"], 
        repLevel = recipeData["repLevel"], 
        season = recipeData["season"], 
        skill = recipeData["skill"], 
        specialization = recipeData["specialization"], 
        teachesItem = recipeData["teachesItem"], 
        teachesSpell = recipeData["teachesSpell"], 
        texture = rTexture
    }
end

local function isTheDisplayedProfession(professionID)
    return L.professions[professionID] == rm.displayedProfession
end

-- Stores all the recipe data for the currently displayed profession
function rm.getProfessionRecipes(getSkillInfoFunction)
    local professionRecipes = {}
    local savedProfessionsAndSkills = rm.getCurrentCharacterSavedVariables()
    for professionID, professionData in pairs(savedProfessionsAndSkills) do
        if isTheDisplayedProfession(professionID) then
            local professionRecipesDatabase = rm.recipeDB[professionID]
            for recipeID, recipeData in pairs(professionRecipesDatabase) do
                if not professionRecipes[recipeID] then
                    local recipe = saveRecipeData(recipeID, recipeData)
                    professionRecipes[recipeID] = recipe
                end
            end
            break
        end
    end
    return professionRecipes
end
