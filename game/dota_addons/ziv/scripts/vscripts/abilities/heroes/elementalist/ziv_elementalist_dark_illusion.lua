function OnModifierDestroy( keys )
	local caster = keys.caster
	local ability = keys.ability

	if ability:GetToggleState() == true then
		End( ability, caster )
	end
end

function End( ability, caster, target )
	local distance = 99999
	local dest = nil
	local target = target or caster:GetAbsOrigin()

	caster:EmitSound("Hero_QueenOfPain.Blink_in")

	ability:ToggleAbility()

	for k,v in pairs(caster.illusions) do
		local new_distance = (v:GetAbsOrigin() - target):Length2D()
		if new_distance < distance then
			distance = new_distance
			dest = v:GetAbsOrigin()
		end
		UTIL_Remove(v)
	end

	caster:SetAbsOrigin(dest)

	Timers:CreateTimer(0.1, function (  )
		TimedEffect( "particles/econ/events/ti4/blink_dagger_start_smoke_ti4.vpcf", caster, 1, 1 )
	end)
	Timers:CreateTimer(0.14, function (  )
		caster:RemoveModifierByName("modifier_dark_illusion_out")
		caster:RemoveNoDraw()

		caster:Stop()
	end)

	ability:StartCooldown(ability:GetCooldown(1))
end

function DarkIllusion( event )
	local caster = event.caster
	local ability = event.ability
	local target = event.target_points[1]

	if ability:GetToggleState() == true then
		End( ability, caster, target )
	else
		local particle = ParticleManager:CreateParticle("particles/econ/events/ti4/blink_dagger_start_smoke_ti4.vpcf",PATTACH_CUSTOMORIGIN,nil)
		ParticleManager:SetParticleControl(particle,0,caster:GetAbsOrigin())
		caster:AddNoDraw()
		-- caster:SetAbsOrigin(target)

		ability:ApplyDataDrivenModifier(caster,caster,"modifier_dark_illusion_out",{})

		local player = caster:GetPlayerID()

		local duration = ability:GetLevelSpecialValueFor( "illusion_duration", ability:GetLevel() - 1 )
		caster.illusions = {}

		local offset = caster:GetAbsOrigin() + Vector(-64,64,0)

		table.insert(caster.illusions, CreateIllusion( ability, caster, player, offset + PointOnCircle(450, 0), duration ))	
		table.insert(caster.illusions, CreateIllusion( ability, caster, player, offset + PointOnCircle(450, 90), duration ))	
		table.insert(caster.illusions, CreateIllusion( ability, caster, player, offset + PointOnCircle(450, 180), duration ))	
		table.insert(caster.illusions, CreateIllusion( ability, caster, player, offset + PointOnCircle(450, 270), duration ))	

		ability:ToggleAbility()

		ability:EndCooldown()
		ability:StartCooldown(GetSpecial(ability, "delay"))
	end
end

function CreateIllusion( ability, caster, player, position, duration )
	local illusion = CreateUnitByName(caster:GetUnitName(), position, true, caster, nil, caster:GetTeamNumber())
	illusion:SetPlayerID(caster:GetPlayerID())
	illusion:SetControllableByPlayer(player, true)
	
	Wearables:InitDefaultWearables(illusion)

	local casterLevel = caster:GetLevel()
	for i=1,casterLevel-1 do
	illusion:HeroLevelUp(false)
	end

	-- illusion:AddNewModifier(illusion, nil, "modifier_kill", {duration = duration})
	illusion:AddNewModifier(illusion,nil,"modifier_transparent",{})
	ability:ApplyDataDrivenModifier(caster,illusion,"modifier_dark_illusion",{})

	TimedEffect( "particles/units/heroes/hero_slark/slark_shadow_dance_dummy.vpcf", illusion, 0.19, 1 )

	local particle1 = ParticleManager:CreateParticle("particles/heroes/elementalist/elementalist_dark_illusion.vpcf",PATTACH_OVERHEAD_FOLLOW,illusion)
	ParticleManager:SetParticleControlEnt(particle1, 1, illusion, PATTACH_POINT_FOLLOW, "attach_orb1", illusion:GetAbsOrigin(), true) 
	local particle2 = ParticleManager:CreateParticle("particles/heroes/elementalist/elementalist_dark_illusion.vpcf",PATTACH_OVERHEAD_FOLLOW,illusion)
	ParticleManager:SetParticleControlEnt(particle2, 1, illusion, PATTACH_POINT_FOLLOW, "attach_orb2", illusion:GetAbsOrigin(), true) 
	local particle3 = ParticleManager:CreateParticle("particles/heroes/elementalist/elementalist_dark_illusion.vpcf",PATTACH_OVERHEAD_FOLLOW,illusion)
	ParticleManager:SetParticleControlEnt(particle3, 1, illusion, PATTACH_POINT_FOLLOW, "attach_orb3", illusion:GetAbsOrigin(), true) 

	illusion:MakeIllusion()

	illusion:SetAngles(0, math.random(0, 360), 0)

	return illusion
end

function OnIllusionDied( keys )
	local caster = keys.caster
	local target = keys.target

	caster:RemoveModifierByName("modifier_dark_illusion_out")
end