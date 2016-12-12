function ZIV:Test()
  local cmdPlayer = Convars:GetCommandClient()
  if cmdPlayer then
    local playerID = cmdPlayer:GetPlayerID()
    if playerID ~= nil and playerID ~= -1 then
      local hero = cmdPlayer:GetAssignedHero()

      -- Account:AddEXP( playerID, 10500 )

      local path = Entities:FindAllByName("ziv_path_*")

      local rNum = 0
      for i=1,#path do
        if not path[i+1] then
          return
        end
        
        local p1 = path[i]:GetAbsOrigin()
        local p2 = path[i+1]:GetAbsOrigin()

        local direction = path[i-1]
        if direction then
          direction = direction:GetAbsOrigin()
        end

        if Distance(p1, p2) > 200 then
          DebugDrawLine(p1 + Vector(0,0,50), p2 + Vector(0,0,50), 255, 0, 255, false, 5.0)
        else
          local p3 = Vector(p1.x, ((p1.y + p2.y) / 2))
          local p4 = Vector(((p1.x + p2.x) / 2), p2.y)

          local curve = BezierCurve:ComputeBezier({p1,p3,p4,p2},100) 

          if rNum % 2 == 0 then
            p3.x = p2.x
            p4.y = p1.y
            curve = BezierCurve:ComputeBezier({p2,p3,p4,p1},100) 
          end

          rNum = rNum + 1

          BezierCurve:Draw(curve, Vector(0,0,180))
        end
        
        curVec = nextVec
      end
    end
  end
end

function ZIV:PrintCreepCount()
  local cmdPlayer = Convars:GetCommandClient()
  if cmdPlayer then
    local playerID = cmdPlayer:GetPlayerID()
    if playerID ~= nil and playerID ~= -1 then
      local hero = cmdPlayer:GetAssignedHero()
      print("creeps:"..tostring(Director.current_session_creep_count))
      print("entities:"..tostring(#Entities:FindAllInSphere(Vector(0,0,0), 100000)))
      for k,v in pairs(Entities:FindAllInSphere(Vector(0,0,0), 100000)) do
        if v:GetClassname() == "npc_dota_creature" then
          print(v:GetUnitName())
        else
          print(k,v:GetClassname())
        end
      end
    end
  end
end

function ZIV:AddAbilityToHero(ability)
  local cmdPlayer = Convars:GetCommandClient()
  if cmdPlayer then
    local playerID = cmdPlayer:GetPlayerID()
    if playerID ~= nil and playerID ~= -1 then
      local hero = cmdPlayer:GetAssignedHero()
      hero:AddAbility(ability)
      InitAbilities(hero)
    end
  end
end

function ZIV:AddModifierToHero(modifier, stacks)
  local cmdPlayer = Convars:GetCommandClient()
  if cmdPlayer then
    local playerID = cmdPlayer:GetPlayerID()
    if playerID ~= nil and playerID ~= -1 then
      local hero = cmdPlayer:GetAssignedHero()
      hero:AddNewModifier(hero,nil,modifier,{})
      hero:SetModifierStackCount(modifier,hero,tonumber(stacks))
    end
  end
end

function ZIV:MakeHeroInvisible()
  local cmdPlayer = Convars:GetCommandClient()
  if cmdPlayer then
    local playerID = cmdPlayer:GetPlayerID()
    if playerID ~= nil and playerID ~= -1 then
      local hero = cmdPlayer:GetAssignedHero()
      hero:AddNewModifier(hero,nil,"modifier_persistent_invisibility",{})
    end
  end
end

function ZIV:PrintHeroStats()
  local cmdPlayer = Convars:GetCommandClient()
  if cmdPlayer then
    local playerID = cmdPlayer:GetPlayerID()
    if playerID ~= nil and playerID ~= -1 then
      local hero = cmdPlayer:GetAssignedHero()
      print("-------------HERO STATS------------")
      print("HP: "..tostring(hero:GetHealth()).."/"..tostring(hero:GetMaxHealth()))
      print("EP: "..tostring(hero:GetMana()).."/"..tostring(hero:GetMaxMana()))
      print("-----------------------------------")
      print("MR: "..tostring(hero:GetMagicalArmorValue()))
      print("ARMOR: "..tostring(hero:GetPhysicalArmorValue()))
      print("FR: "..tostring(Damage:GetResist( hero, Damage.FIRE_RESISTANCE )))
      print("CR: "..tostring(Damage:GetResist( hero, Damage.COLD_RESISTANCE )))
      print("LR: "..tostring(Damage:GetResist( hero, Damage.LIGHTNING_RESISTANCE )))
      print("DR: "..tostring(Damage:GetResist( hero, Damage.DARK_RESISTANCE )))
      print("-----------------------------------")
      print("STR: "..tostring(hero:GetStrength()))
      print("AGI: "..tostring(hero:GetAgility()))
      print("INT: "..tostring(hero:GetIntellect()))
      print("-----------------------------------")
      print("AD: "..tostring(hero:GetAverageTrueAttackDamage(hero)))
      print("AS: "..tostring(hero:GetAttackSpeed()))
      print("ApS: "..tostring(hero:GetAttacksPerSecond()))
      print("-----------------------------------")
      print("MODIFIER COUNT: "..tostring(hero:GetModifierCount()))
      print("-----------------------------------")
      for i=0,hero:GetModifierCount() do
        print(hero:GetModifierNameByIndex(i), hero:GetModifierStackCount(hero:GetModifierNameByIndex(i), hero))
      end
      for i=0,16 do
        local abil = hero:GetAbilityByIndex(i)
        if abil then
          print(abil:GetName())
        end
      end
      print("-----------------------------------")
    end
  end
end

function ZIV:AddItemToContainer(item, count)
  local cmdPlayer = Convars:GetCommandClient()
  if cmdPlayer then
    local playerID = cmdPlayer:GetPlayerID()
    if playerID ~= nil and playerID ~= -1 then
      local hero = cmdPlayer:GetAssignedHero()
      local item = Items:Create(item, hero)
      hero.inventory:AddItem(item, tonumber(count) or nil)
    end
  end
end

function ZIV:SpawnBasicPack(count, pack_type, modifier)
  local cmdPlayer = Convars:GetCommandClient()
  if cmdPlayer then
    local playerID = cmdPlayer:GetPlayerID()
    if playerID ~= nil and playerID ~= -1 then
      local hero = cmdPlayer:GetAssignedHero()
      
      Director:SpawnPack(
        {
          Level = 1,
          SpawnBasic = true,
          Count = tonumber(count) or 10,
          Type = pack_type or "creep",
          Position = hero:GetAbsOrigin(),
          BasicModifier = "ziv_creep_modifier_fire_bomb",
          LordModifier = "ziv_creep_lord_modifier_regen_aura",
          SpawnLord = true
        }
      )
    end
  end
end

function ZIV:SpawnBasicDrop(rarity)
  local cmdPlayer = Convars:GetCommandClient()
  if cmdPlayer then
    local playerID = cmdPlayer:GetPlayerID()
    if playerID ~= nil and playerID ~= -1 then
      local hero = cmdPlayer:GetAssignedHero()

      Loot:CreateChest( hero:GetAbsOrigin(), tonumber(rarity) )
    end
  end
end