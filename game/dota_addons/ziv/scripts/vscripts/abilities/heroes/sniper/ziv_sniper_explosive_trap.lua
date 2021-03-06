function CreateTrapUnit( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target_points[1]

	local duration = ability:GetLevelSpecialValueFor("trap_duration", ability:GetLevel())

	local trap = CreateUnitByName("npc_explosive_trap", target, false, caster, caster, caster:GetTeamNumber())
	trap:AddNewModifier(caster,ability,"modifier_hide_health_bar",{})

	InitAbilities(trap)

	trap.sparks = ParticleManager:CreateParticle("particles/heroes/sniper/sniper_explosive_trap_sparks.vpcf", PATTACH_CUSTOMORIGIN, trap)
	ParticleManager:SetParticleControl(trap.sparks, 0, trap:GetAbsOrigin() + Vector(0,0,32))

	keys.trap = trap

	TrapTimer( keys, CheckUnits, RemoveTrapUnit, duration )
end

function RemoveTrapUnit( keys )
	local caster = keys.caster
	local trap = keys.trap
	local ability = keys.ability

	if trap then
		trap:EmitSound("Tutorial.Notice.Speech")

		local delay = GetRunePercentDecrease(1.0,"ziv_sniper_explosive_trap_delay",caster) -- GetSpecial(ability, "delay")

		Timers:CreateTimer(delay, function (  )
			Explode( keys )
		end)

		trap.worldPanel = WorldPanels:CreateWorldPanelForAll(
		    {layout = "trap_countdown",
		      entity = trap:GetEntityIndex(),
		      data = { delay = delay },
		      entityHeight = 170,
		    })
	end
end

function Explode( keys )
	local caster = keys.caster
	local trap = keys.trap
	local ability = keys.ability

	if trap then
		local units_in_radius = FindUnitsInRadius(caster:GetTeamNumber(), trap:GetAbsOrigin(),  nil, ability:GetSpecialValueFor("trap_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)

		if #units_in_radius > 0 then
			for k,v in pairs(units_in_radius) do
				ability:ApplyDataDrivenModifier(caster, v, "modifier_explosive_trap_effect", {})
				
				Damage:Deal( caster, v, GetRuneDamage(caster, GetSpecial(ability, "damage_amp"), "ziv_sniper_explosive_trap_damage"), DAMAGE_TYPE_FIRE )
			end
		end

		ParticleManager:DestroyParticle(trap.sparks,true)

		local explosion = ParticleManager:CreateParticle("particles/econ/items/clockwerk/clockwerk_paraflare/clockwerk_para_rocket_flare_explosion.vpcf", PATTACH_ABSORIGIN, trap)
		ParticleManager:SetParticleControl(explosion, 3, trap:GetAbsOrigin() + Vector(0,0,128))

		local explosion2 = ParticleManager:CreateParticle("particles/units/heroes/hero_batrider/batrider_flamebreak_explosion.vpcf", PATTACH_CUSTOMORIGIN, trap)
		ParticleManager:SetParticleControl(explosion2, 3, trap:GetAbsOrigin() + Vector(0,0,128))

		ParticleManager:CreateParticle("particles/generic_gameplay/dust_impact_large.vpcf", PATTACH_CUSTOMORIGIN, trap)
		ParticleManager:CreateParticle("particles/neutral_fx/roshan_slam_debris_small.vpcf", PATTACH_CUSTOMORIGIN, trap)
		trap:EmitSound("Hero_Techies.LandMine.Detonate")

		trap:SetModel("models/development/invisiblebox.vmdl")
		trap:SetOriginalModel("models/development/invisiblebox.vmdl")

		Timers:CreateTimer(1.0, function (  )
			trap:RemoveSelf()
		end)
	end
end