function Animation( keys )
	local caster = keys.caster
	local ability = keys.ability

	StartAnimation(caster, {duration=GetRunePercentDecrease(1.0,"ziv_dark_goddess_transform_speed",caster), activity=ACT_DOTA_SPAWN, rate=GetRunePercentIncrease(1.3,"ziv_dark_goddess_transform_speed",caster)})

	caster:EmitSound("Hero_DrowRanger.Transform")

	Transform( keys )
end

function Transform( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target_points[1]

	StartRuneCooldown(ability,"ziv_dark_goddess_transform_cd",caster)

	local units = caster.child_entities or {}

	for i=#units,1,-1 do
		local v = units[i]
	    
	    if IsValidEntity(v) then
			if v:HasModifier("modifier_glaive_unit") == true then
				TransformPosition( caster, ability, v:GetAbsOrigin() )

				Timers:CreateTimer(0.1, function (  )
					caster:EmitSound("Hero_Luna.MoonGlaive.Impact")
					UTIL_Remove(v)
				end)
				return
			else
				table.remove(caster.child_entities, i)
			end
		else
			if v.GetVelocity and v.GetPosition then
				if not v.IsNull and Projectiles.timers[v.ProjectileTimerName] ~= nil then
					TransformPosition( caster, ability, v:GetPosition() )

					Timers:CreateTimer(0.1, function (  )
						v:Destroy()
					end)
					return
				end
			else
				table.remove(caster.child_entities, i)
			end
		end
	end

	TransformPosition( caster, ability, caster:GetAbsOrigin() )
end

function TransformPosition( caster, ability, position )
	caster:SetForwardVector(UnitLookAtPoint( caster, position ))
	caster:Stop()

	ability:ApplyDataDrivenModifier(caster,caster,"modifier_dark_goddess_transform",{duration=GetRunePercentDecrease(0.5,"ziv_dark_goddess_transform_speed",caster) })

	Timers:CreateTimer(GetRunePercentDecrease(0.1,"ziv_dark_goddess_transform_speed",caster), function (  )
		if caster:HasModifier("modifier_dark_goddess_transform") then
			FindClearSpaceForUnit(caster,position,false)
			ProjectileManager:ProjectileDodge(caster)

			caster:AddNewModifier(caster,nil,"modifier_rooted",{duration = 0.9})

			Timers:CreateTimer(function (  )
				caster:Stop()
				local particle = TimedEffect("particles/heroes/dark_goddess/dark_goddess_transform.vpcf", caster, 2.0, 3)
				local orientation = caster:GetForwardVector()
				-- ParticleManager:SetParticleControlOrientation(particle,3,orientation,Vector(0,1,0),Vector(1,0,0))
				ParticleManager:SetParticleControlForward(particle,3,orientation)

				TimedEffect("particles/heroes/dark_goddess/dark_goddess_transform_flies.vpcf", caster, 2.0, 3, PATTACH_OVERHEAD_FOLLOW)
			end)
		else
			EndAnimation(caster)
		end
	end)
end