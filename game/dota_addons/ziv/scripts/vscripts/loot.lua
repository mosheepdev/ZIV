if Loot == nil then
    _G.Loot = class({})
end

Loot.RARITY_COMMON = 0
Loot.RARITY_MAGIC = 1
Loot.RARITY_RARE = 2
Loot.RARITY_EPIC = 3
Loot.RARITY_LEGENDARY = 4

Loot.RARITY_PARTICLES = {}
Loot.RARITY_PARTICLES[Loot.RARITY_MAGIC] = "particles/items/ziv_chest_light_magic.vpcf"
Loot.RARITY_PARTICLES[Loot.RARITY_RARE] = "particles/items/ziv_chest_light_rare.vpcf"
Loot.RARITY_PARTICLES[Loot.RARITY_EPIC] = "particles/items/ziv_chest_light_epic.vpcf"
Loot.RARITY_PARTICLES[Loot.RARITY_LEGENDARY] = "particles/items/ziv_chest_light_legendary.vpcf"

Loot.CHEST_MODELS = {}
Loot.CHEST_MODELS[1] = "item_basic_chest_lockjaw"
Loot.CHEST_MODELS[2] = "item_basic_chest_flopjaw"
Loot.CHEST_MODELS[3] = "item_basic_chest_mechjaw"
Loot.CHEST_MODELS[4] = "item_basic_chest_trapjaw"

Loot.CommonModifiers = {}
Loot.RuneModifiers = {}

Loot.Table = LoadKeyValues('scripts/kv/LootTable.kv')

function IsItemDropped( chance )
  return math.random(100) < chance
end

function Loot:Init()
	for k,v in pairs(ZIV.AbilityKVs["ziv_passive_hero"]["Modifiers"]) do
		if string.match(k, "MODIFIER_PROPERTY") then
			Loot.CommonModifiers[k] = v
		elseif string.match(k, "ziv_") then
			Loot.RuneModifiers[k] = v
		end
	end
end

function Loot:CreateChest( pos, rarity )
	local chest = CreateItemOnPositionSync(pos, CreateItem(Loot.CHEST_MODELS[math.random(1, GetTableLength(Loot.CHEST_MODELS))], nil, nil))
	CreateItemPanel( chest )
	chest.rarity = rarity or (math.random(0, 4))

	chest:SetAngles(0, math.random(0, 360), 0)
	Timers:CreateTimer(function (  )
		local particle = ParticleManager:CreateParticle(Loot.RARITY_PARTICLES[chest.rarity], PATTACH_ABSORIGIN_FOLLOW, chest)
		ParticleManager:SetParticleControl(particle, 0, chest:GetAbsOrigin())

		AddChildParticle( chest, particle )
	end)
end

function Loot:GetLootTable( creep )
  if Loot.Table == nil then
    return nil
  end
  -- Get loot table
  return Loot.Table[creep:GetUnitName()]
end

function Loot:Generate( creep, killer )
	local lootTable = Loot:GetLootTable( creep )

	if killer:IsHero() == false  then
		if not PlayerResource:GetPlayer(killer:GetPlayerOwnerID()) then return end
		killer = PlayerResource:GetPlayer(killer:GetPlayerOwnerID()):GetAssignedHero()
	end

	if lootTable ~= nil and IsItemDropped(lootTable.LootChance or 0) then
    	Loot:CreepDrops( lootTable, creep, killer )
    	if lootTable.Preset then 
    		Loot:CreepDrops( Loot.Table[lootTable.Preset], creep, killer ) 
    	end
	end

	local vial = CreateVial( killer, creep:GetAbsOrigin() + Vector(math.random(-20,20),math.random(-20,20), 0) )

	if vial then
		PrepareVial( vial )
	end
end

function Loot:AddModifiers(item)
	local modifier_count = item.rarity + math.random(0, 2)
	item.built_in_modifiers = item.built_in_modifiers or {}

	local all_modifiers = Loot.CommonModifiers
	-- if string.match(item:GetName(), "item_rune_") then 
	-- 	all_modifiers = Loot.CommonModifiers
	-- end

	for i=1,modifier_count do
		local seed = math.random(1, GetTableLength(all_modifiers))
		local x = 1
		for k,v in pairs(all_modifiers) do
			if x == seed then
				item.built_in_modifiers[k] = item.built_in_modifiers[k] or 0
				item.built_in_modifiers[k] = item.built_in_modifiers[k] + math.random(1,12)
				break
			end
			x = x + 1
		end
	end
end

function Loot:CombineLootTables(table1, table2)
	if not table1 then return table2 end
	if not table2 then return table1 end

	local new_table = table1.Loot
	local length = GetTableLength(table1.Loot)
	for k,v in pairs(table2.Loot) do
		new_table[tostring(length+tonumber(k))] = v
	end
	
	return new_table
end

function Loot:RandomItemFromLootTable( lootTable, chest_unit, owner )
	if not lootTable then return end

	local itemName = ""

	local seed = math.random(100)
  	local rarity = nil
  	local items = nil

	if type(lootTable) == "table" and lootTable.Loot then
	  	-- Random rarity
	  	local num = 0
	  	for k,v in pairs(lootTable.Loot) do
	    	if seed > num and seed <= num + v.Chance then
	      		rarity = tonumber(k)
	      		items = v.Items
	    	end
	    
	    	num = num + v.Chance
	  	end
	  
	  	-- Random item in group
	  	itemName = items[tostring(math.random(0, GetTableLength(items) - 1))]
	else
		itemName = lootTable
	end

	if not itemName or type(itemName) ~= "string" then return nil end

	local item = CreateItem(itemName, owner, owner)

  	local container = CreateItemOnPositionSync(chest_unit:GetAbsOrigin(), item)
  
  	-- Random item rotation
  	container:SetAngles(0, math.random(0, 360), 0)
  	local new_item = container:GetContainedItem()

  	new_item.rarity = 0

  	if rarity > Loot.RARITY_COMMON and not string.match(new_item:GetName(), "gem") then
    	if i == count then
      		new_item.rarity = rarity
    	elseif math.random(0,1) == 0 then
        	new_item.rarity = math.abs(math.random(0,rarity-1))
      	end
    end

    if new_item.rarity > 0 then 
      	Loot:AddModifiers(new_item)

      	local particle = ParticleManager:CreateParticle(Loot.RARITY_PARTICLES[new_item.rarity], PATTACH_ABSORIGIN_FOLLOW, container)
      	ParticleManager:SetParticleControl(particle, 0, container:GetAbsOrigin())
      	container.particles = {}
      	table.insert(container.particles, particle)
 	end
  
  	return container
end

function Loot:CreepDrops( lootTable, creep, killer )
	local count = math.random(1, lootTable.Max)
  	local i = 1
  
	Timers:CreateTimer(function ()
		if i < count then
			i = i + 1

			local item = Loot:RandomItemFromLootTable( lootTable, creep, killer )
			if item then
				Loot:SpawnPhysicalItem(item)
			end

			return math.random(0.21, 0.41)
		end
	end)
end

function Loot:OpenChest( chest, unit )
	local chest_unit = CreateUnitByName("npc_basic_chest",chest:GetAbsOrigin(),false,nil,nil,unit:GetTeamNumber())

	chest_unit:SetModel(ZIV.ItemKVs[chest:GetContainedItem():GetName()]["Model"])
	chest_unit:SetOriginalModel(ZIV.ItemKVs[chest:GetContainedItem():GetName()]["Model"])

	InitAbilities(chest_unit)
	chest:RemoveSelf()

  	local lootTable = Loot:GetLootTable( chest_unit )
  
  	if lootTable == nil then
    	return
  	end
  
	local count = math.random(1, lootTable.Max)
	local i = 1
  
	Timers:CreateTimer(function ()
		if i <= count then
			i = i + 1

			Loot:SpawnPhysicalItem(Loot:RandomItemFromLootTable( lootTable, chest_unit, nil ))

			return math.random(0.31, 0.41)
		else
			Timers:CreateTimer(0.3, function (  )
				chest_unit:RemoveModifierByName("dummy_unit")
				chest_unit:RemoveAbility("dummy_unit")
				DestroyEntityBasedOnHealth(chest_unit, chest_unit)
			end)
		end
	end) 
end

function Loot:SpawnPhysicalItem(new_item_c, no_panel)
	if not no_panel then CreateItemPanel( new_item_c ) end

	Physics:Unit(new_item_c)

	local seed = math.random(0, 360)
	local boost = math.random(0,325)

	local x = ((185 + boost) * math.cos(seed))
	local y = ((185 + boost) * math.sin(seed))

	new_item_c:AddPhysicsVelocity(Vector(x, y, 1100))
	new_item_c:SetPhysicsAcceleration(Vector(0,0,-1700))

	EmitSoundOn("Item.DropWorld",new_item_c)
end