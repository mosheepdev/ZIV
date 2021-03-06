function OnStartTouch(trigger)
	local unit = trigger.activator
	local caller = trigger.caller

	local pID = unit:GetPlayerOwnerID()

 	local trigger_name = caller:GetName()

 	if string.match(trigger_name, "fortify") then
 		CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(pID), "ziv_set_fortify_button", {  } )
 	elseif string.match(trigger_name, "crafting") then
 		CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(pID), "ziv_set_crafting_button", {  } )
 	end

 	AddTrigger( unit, caller )
end
 
function OnEndTouch(trigger)
	local unit = trigger.activator
	local caller = trigger.caller

	RemoveTrigger( unit, caller )

	local pID = unit:GetPlayerOwnerID()

	-- Check for fortify and crafting triggers to gray out button
	for i=GetTableLength( unit.triggers ),1,-1 do
		local name = unit.triggers[i]:GetName()
    	if string.match(name, "fortify") or string.match(name, "crafting") then
	        return
	    end
	end
	
	CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(pID), "ziv_set_grayout_button", {  } )
end

function AddTrigger( unit, trigger )
	unit.triggers = unit.triggers or {}
	table.insert(unit.triggers, trigger)
end

function RemoveTrigger( unit, trigger )
	unit.triggers = unit.triggers or {}

	for i=GetTableLength( unit.triggers ),1,-1 do
    	if unit.triggers[i] == trigger then
	        table.remove(unit.triggers, i)
	        return
	    end
	end
end

function RemoveTriggersByName( unit, trigger_name )
	unit.triggers = unit.triggers or {}

	for i=GetTableLength( unit.triggers ),1,-1 do
    	if unit.triggers[i] and unit.triggers[i]:GetName() == trigger_name then
	        table.remove(unit.triggers, trigger)
	    end
	end
end