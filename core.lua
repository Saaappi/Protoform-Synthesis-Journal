local addonName, addon = ...
local e = CreateFrame("Frame")

local function AddText(tooltip, leftText, rightText)
	local frame, text
	for i = 1, 30 do
		frame = _G[tooltip:GetName() .. "TextLeft" .. i]
		if frame then text = frame:GetText() end
		if text and string.find(text, addonName) then return end
	end

	tooltip:AddLine("\n")
	tooltip:AddDoubleLine(leftText, rightText)
	tooltip:Show()
end

local function OnTooltipSetItem(tooltip)
	if (tooltip) then
		local _, _, itemID = TooltipUtil.GetDisplayedItem(tooltip)
		if not itemID then return end

		if (PSJ_Account[itemID]) then
			if ((PSJ_Account[itemID].quantityRequired-GetItemCount(itemID, true)) > 0) then
				AddText(tooltip, "|cff00FAF6"..addonName.."|r", "|cff00FAF6"..(PSJ_Account[itemID].quantityRequired-GetItemCount(itemID, true)).."|r")
			else
				AddText(tooltip, "|cff00FAF6"..addonName.."|r", "|cff00FAF6".."0|r")
			end
		end
	end
end

local function Calculate()
	local categoryID = C_TradeSkillUI.GetCategories()
	if (categoryID == 1548) then -- Protoform Synthesis
		C_Timer.After(1, function()
			local recipes = C_TradeSkillUI.GetAllRecipeIDs()
			local numPets = C_PetJournal.GetNumPets()
			for _, recipeID in ipairs(recipes) do
				local recipeInfo = C_TradeSkillUI.GetRecipeInfo(recipeID)
				local itemType = select(7, GetItemInfo(recipeInfo.hyperlink))
				local itemID = GetItemInfoInstant(recipeInfo.hyperlink)
				if (itemType == "Companion Pets") then
					local petName = C_PetJournal.GetPetInfoByItemID(itemID)
					for i = 1, numPets do
						local owned, _, _, _, _, currentPetName = select(3, C_PetJournal.GetPetInfoByIndex(i))
						if (currentPetName == petName) then
							if (not owned) then
								local reagents = C_TradeSkillUI.GetRecipeSchematic(recipeID, false).reagentSlotSchematics
								for _, reagent in ipairs(reagents) do
									if (not PSJ_Account[reagent.reagents[1].itemID]) then
										PSJ_Account[reagent.reagents[1].itemID] = {}
										PSJ_Account[reagent.reagents[1].itemID] = {itemLink = "", quantityRequired = 0}
									end
									C_Item.RequestLoadItemDataByID(reagent.reagents[1].itemID)
									C_Timer.After(0.25, function()
										local _, itemLink = GetItemInfo(reagent.reagents[1].itemID)
										PSJ_Account[reagent.reagents[1].itemID].itemLink = itemLink
										PSJ_Account[reagent.reagents[1].itemID].quantityRequired = PSJ_Account[reagent.reagents[1].itemID].quantityRequired + reagent.quantityRequired
									end)
								end
								print("Done calculating for "..currentPetName)
							end
						end
					end
				elseif (itemType == "Mount") then
					local mountID = C_MountJournal.GetMountFromItem(itemID)
					local mountName, _, _, _, _, _, _, _, _, _, collected = C_MountJournal.GetMountInfoByID(mountID)
					if (not collected) then
						local reagents = C_TradeSkillUI.GetRecipeSchematic(recipeID, false).reagentSlotSchematics
						for _, reagent in ipairs(reagents) do
							if (not PSJ_Account[reagent.reagents[1].itemID]) then
								PSJ_Account[reagent.reagents[1].itemID] = {}
								PSJ_Account[reagent.reagents[1].itemID] = {itemLink = "", quantityRequired = 0}
							end
							C_Item.RequestLoadItemDataByID(reagent.reagents[1].itemID)
							C_Timer.After(0.25, function()
								local _, itemLink = GetItemInfo(reagent.reagents[1].itemID)
								PSJ_Account[reagent.reagents[1].itemID].itemLink = itemLink
								PSJ_Account[reagent.reagents[1].itemID].quantityRequired = PSJ_Account[reagent.reagents[1].itemID].quantityRequired + reagent.quantityRequired
							end)
						end
					end
					print("Done calculating for "..mountName)
				end
			end
		end)
	end
end

e:RegisterEvent("ADDON_LOADED")
e:SetScript("OnEvent", function(self, event, ...)
	if (event == "ADDON_LOADED") then
		local addonLoaded = ...
		if (addonLoaded == addonName) then
			if (PSJ_Account == nil) then
				PSJ_Account = {}
			end
		end
	end
end)

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)

SLASH_ProtoformSynthesisJournal1 = "/psj"
SlashCmdList["ProtoformSynthesisJournal"] = function(cmd)
	local cmd, arg1, arg2 = string.split(" ", cmd)
	if (not cmd) or (cmd == "") then
	elseif (cmd == "calculate") then
		Calculate(true)
	elseif (cmd == "wipe") then
		PSJ_Account = {}
		print("Wiped saved variables...")
	end
end