function CreateTotem( keys )
	local caster = keys.caster
	local target = keys.target_points[1]
	local ability = keys.ability

	PrecacheUnitByNameAsync("npc_witch_doctor_totem", function (  )
		StartSoundEvent("Hero_WitchDoctor.Death_WardBuild",caster)

		local duration = ability:GetLevelSpecialValueFor("totem_duration", ability:GetLevel())

		local totem = CreateUnitByName("npc_witch_doctor_totem", target, false, nil, caster:GetPlayerOwner(), caster:GetTeamNumber())
		totem:AddNewModifier(totem, ability, "modifier_kill", {duration = duration})
		ability:ApplyDataDrivenModifier(caster,totem,"modifier_witch_doctor_totem",{duration = duration})
		totem:SetModifierStackCount("modifier_witch_doctor_totem",caster,GRMSC("ziv_witch_doctor_totem_range", caster))

		local particle = ParticleManager:CreateParticle("particles/heroes/witch_doctor/witchdoctor_totem_skull.vpcf",PATTACH_POINT,totem)
		ParticleManager:SetParticleControlEnt(particle, 0, totem, PATTACH_POINT_FOLLOW, "attach_attack1", totem:GetAbsOrigin(), false)
		ParticleManager:SetParticleControl(particle, 2, totem:GetAbsOrigin())

		AddChildParticle( totem, particle )
	end, caster:GetPlayerOwnerID())
end

function CreateTotem2( keys )
	local caster = keys.caster
	local target = keys.target_points[1]
	local ability = keys.ability

	PrecacheUnitByNameAsync("npc_witch_doctor_totem2", function (  )
		local duration = ability:GetLevelSpecialValueFor("totem_duration", ability:GetLevel()) + (GRMSC("ziv_witch_doctor_totem2_duration", caster) / 100)

		local totem = CreateUnitByName("npc_witch_doctor_totem2", target, false, nil, caster:GetPlayerOwner(), caster:GetTeamNumber())
		totem:AddNewModifier(totem, ability, "modifier_kill", {duration = duration})
		ability:ApplyDataDrivenModifier(totem,totem,"modifier_witch_doctor_totem2",{duration = duration})

		Timers:CreateTimer(0.3, function (  )
			local particle = ParticleManager:CreateParticle("particles/heroes/witch_doctor/witch_doctor_totem2_fx.vpcf",PATTACH_OVERHEAD_FOLLOW,totem)

			AddChildParticle( totem, particle )

			if totem:IsNull() ~= true and totem:IsAlive() ~= false then return 0.8 end
		end)
	end, caster:GetPlayerOwnerID())
end

function RemoveTotem( keys )
	local caster = keys.caster

	if string.match(caster:GetUnitName(), "npc_witch_doctor_totem") then
		StopSoundEvent("Hero_WitchDoctor.Death_WardBuild",caster)
	end
end

function SplitShot( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local totem = keys.attacker
	
	if caster:IsNull() == false then
		totem:EmitSound("Hero_WitchDoctor_Ward.Attack")
		local units = FindUnitsInRadius(caster:GetTeamNumber(), totem:GetAbsOrigin(),  nil, totem:GetAttackRange(), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)

		local targets = ability:GetSpecialValueFor("totem_targets") + GRMSC("ziv_witch_doctor_totem_targets", caster)
		local i = 1
		for k,v in pairs(units) do
			if i >= targets then break end
			if v ~= target then 
				local projectile_info = 
			    {
			        EffectName = "particles/heroes/witch_doctor/witch_doctor_totem_projectile.vpcf",
			        Ability = ability,
			        vSpawnOrigin = target:GetAbsOrigin(),
			        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
			        Target = v,
			        Source = totem,
			        bHasFrontalCone = false,
			        iMoveSpeed = totem:GetProjectileSpeed(),
			        bReplaceExisting = false,
			        bProvidesVision = false
			    }
		    	ProjectileManager:CreateTrackingProjectile(projectile_info)
		    	i = i + 1
			end
		end
	end
end

function SplitShotImpact( keys )
    local caster = keys.caster
    local target = keys.target
    local ability = keys.ability
    local attacker = keys.attacker

    Damage:Deal( caster, target, GetRuneDamage(caster, GetSpecial(ability, "damage_amp"), ""), DAMAGE_TYPE_DARK )
end

function Pulling( keys )
	local caster = keys.caster
    local target = keys.target
    local ability = keys.ability

    if not caster:HasMovementCapability() then return end

    if not target.pulling then
    	target.pulling = ParticleManager:CreateParticle("particles/heroes/witch_doctor/witch_doctor_totem2_lasso.vpcf", PATTACH_CUSTOMORIGIN, caster)

    	ParticleManager:SetParticleControlEnt(target.pulling, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin() + Vector(0,0,16), true)
    	ParticleManager:SetParticleControlEnt(target.pulling, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin() + Vector(0,0,16), true)
    
    	Timers:CreateTimer(0.3, function (  )
    		ParticleManager:DestroyParticle(target.pulling,false)
    		target.pulling = nil
    	end)
    end

    local caster_position = caster:GetAbsOrigin()
    local target_position = target:GetAbsOrigin()

    local angle = math.atan2(target_position.y - caster_position.y, target_position.x - caster_position.x)

    local force = GetSpecial(ability, "force") + GRMSC("ziv_witch_doctor_totem2_force", caster)

	target_position.x = target_position.x - (math.cos(angle) * force)
	target_position.y = target_position.y - (math.sin(angle) * force)

	local speed = 2.5

	local time = 0
    Timers:CreateTimer(function ()
    	if time < 0.35 then
	    	-- if (caster_position - caster_position):Length() > 30 then return end

			FindClearSpaceForUnit(target, lerp_vector(target:GetAbsOrigin(), target_position, 0.03 * speed), false)
			time = time + 0.03
	    	return 0.03
    	end
    end)
end