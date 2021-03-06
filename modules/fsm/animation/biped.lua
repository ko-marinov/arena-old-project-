local moduleFsm = require "modules.fsm"
local moduleAttackFsm = require "modules.fsm.attack.attack"

local function playAnim(fsm, animId)
	fsm.anim_controller.PlayAnim(animId)
end

local M = {}

function M.new(anim_controller, dbgName)
	-------------------------------------------------------------------------------------------------
	----------------------------- Player animation finite state machine -----------------------------
	-------------------------------------------------------------------------------------------------
	-- ** Name convention **
	--
	-- I. Events
	--
	-- 1. Active verb
	-- 2, Lowercase
	-- 3. In one word
	-- Examples: attack, fall, die, takedamage
	--
	-- II. States
	--
	-- 1. Clear nouns without '-ing' and '-ed'
	-- 2. Uppercase
	-- 3. Words splitted up by underscores
	-- Examples: OFFENSIVE (instead of ATTACKING ('-ing' is forbidden) or ATTACK (unclear, 'to attack'))
	--           IN_AIR or AIRBORNE (instead of FALLING or FALL)
	--           IDLE (its known word for inactivity state, so there is no ambiguity)
	--
	-- TODO: Each transition in separate line
	-------------------------------------------------------------------------------------------------

	local fsm = moduleFsm.create({
		initial = "IDLE",
		events = {
			{ name = "run", 			from = "IDLE", 									to = "IN_MOTION"	},
			{ name = "stop",  			from = "IN_MOTION", 							to = "IDLE" 		},
			{ name = "attack", 			from = { "IDLE", "IN_MOTION", "OFFENSIVE" },	to = "OFFENSIVE"	},
			{ name = "finishattack",	from = { "OFFENSIVE" },							to = "IDLE" 		},
			{ name = "fall", 			from = { "IDLE", "IN_MOTION", "OFFENSIVE" }, 	to = "AIRBORNE"		},
			{ name = "takedamage", 		from = "*", 									to = "INJURY"		},
			{ name = "die", 			from = "*", 									to = "DEATH" 		},
			{ name = "land", 			from = "AIRBORNE", 								to = "IDLE" 		},
			{ name = "toidle",	 		from = "*", 									to = "IDLE" 		},
			{ name = "roll",			from = { "IDLE", "IN_MOTION" },					to = "ROLL"			}
		},
		dbgName = dbgName or "FSM:Anim"
	})

	-- fsm extension --
	fsm.blackboard						= {}
	fsm.blackboard[cmn.param_move]		= 0
	fsm.blackboard[cmn.param_vvel]		= 0
	fsm.blackboard[cmn.tag_grounded]	= false
	fsm.blackboard[cmn.tag_attack]		= false
	fsm.blackboard[cmn.tag_hurt]		= false
	fsm.blackboard[cmn.tag_dead]		= false

	--[[
	local weaponStats = {
		prepTime	= 0.5,									-- time before hit
		relaxTime	= 0.5,									-- time after hit and before next hit
		animSet 	= "sword",								-- set of owner's animations
		animNum 	= 3,									-- number of animations in animation set
		hitLogic	= function(relaxTransitionClbk, fsm)	-- actions to do on hit
			local timerClbck = function(self, handle, time_elapsed)
				msg.post(".", "stop_damage")
				fsm[relaxTransitionClbk](fsm)
			end

			timer.delay(0.08, false, timerClbck)
			msg.post(".", "start_damage")
		end
	}
	--]]

	fsm.attackFsm					= moduleAttackFsm.new(anim_controller, weaponStats)
	fsm.anim_controller				= anim_controller
	
	-- on enter state IDLE
	fsm.onIDLE = function(event, from, to)
		playAnim(fsm, hash("idle"))
	end

	-- on enter state IN_MOTION
	fsm.onIN_MOTION = function(event, from, to)
		playAnim(fsm, hash("run"))
	end

	fsm.onbeforeattack = function(event, from, to)
		fsm.attackFsm.requestAttack()
	end

	fsm.onmessageOFFENSIVE = function(message_id, message, sender)
		fsm.attackFsm.on_message(message_id, message, sender)
	end

	fsm.onROLL = function(event, from, to)
		playAnim(fsm, hash("roll"))
	end

	-- TODO: watch out, copypaste from INJURY
	fsm.onmessageROLL = function(message_id, message, sender)
		if message_id == cmn.msgtype_anim_event then
			if message.id == cmn.anim_finished	and message.animId == hash("roll") then
				fsm:toidle()
			end
		end
	end

	-- on enter state AIRBORNE
	fsm.onAIRBORNE = function(event, from, to)
		playAnim(fsm, hash("fall"))
	end

	-- on enter state INJURY
	fsm.onINJURY = function(event, from, to)
		playAnim(fsm, hash("hurt"))
		msg.post(".", cmn.msgtype_tag, { id = cmn.tag_hurt, value = true })	-- TODO: Post tags from anim fsm is smells?!
	end

	fsm.onbeforetakedamage = function(event, from, to)
		if fsm.current == "INJURY" or fsm.current == "DEATH" then
			return false
		end

		return true
	end

	fsm.onmessageINJURY = function(message_id, message, sender)
		if message_id == cmn.msgtype_anim_event then
			if message.id == cmn.anim_finished	and message.animId == hash("hurt") then
				msg.post(".", cmn.msgtype_tag, { id = cmn.tag_hurt, value = false })
				fsm:toidle()
			end
		end
	end

	-- on enter state DEATH
	fsm.onDEATH = function(event, from, to)
		playAnim(fsm, hash("die"))
	end

	fsm.onbeforedie = function(event, from, to)
		if fsm.current == "DEATH" then
			return false
		end
		return true
	end

	----------------------------------------------
	-- fsm extension 							--
	-- can be added into module					--
	----------------------------------------------
	fsm.abortMelee = function()
		if fsm.attackFsm.isAttacking() then
			fsm.attackFsm.requestAbort()
		end
	end
	
	fsm.tryDie = function()
		if fsm.blackboard[cmn.tag_dead] then
			fsm.abortMelee()
			fsm:die()
		end
	end

	fsm.tryTakeDamage = function()
		if fsm.blackboard[cmn.tag_hurt] then
			fsm.abortMelee()
			fsm:takedamage()
		end
	end

	fsm.updateAirborne = function()
		if fsm.blackboard[cmn.tag_grounded] then 
			fsm:land()
		else
			fsm:fall()
		end
	end

	fsm.updateMovement = function()
		if fsm.blackboard[cmn.param_move] == 0 then
			fsm:stop()
		else
			fsm:run()
		end
	end

	fsm.updateOffensive = function()
		if fsm.current ~= "OFFENSIVE" and fsm.attackFsm.isAttacking() then
			fsm:attack()
		elseif fsm.current == "OFFENSIVE" and not fsm.attackFsm.isAttacking() then
			fsm:finishattack()
		end
	end

	fsm.updateDirection = function()
		if fsm.blackboard[cmn.param_move] ~= 0 then
			sprite.set_hflip("#sprite", fsm.blackboard[cmn.param_move] < 0)
		end
	end

	fsm.SetWeaponStats = function(weaponStats)
		fsm.attackFsm.SetWeaponStats(weaponStats)
	end

	fsm.update = function(dt)
		fsm.tryDie()
		fsm.tryTakeDamage()
		fsm.updateAirborne()
		fsm.updateOffensive()
		fsm.updateMovement()
		fsm.updateDirection()
	end

	fsm.on_message = function(message_id, message, sender)
		if message_id == hash("weapon_changed") then
			fsm.SetWeaponStats(message.weaponStats)
		elseif message_id == cmn.msgtype_param or message_id == cmn.msgtype_tag then
			if fsm.blackboard[message.id] ~= nil then		-- to avoid blackboard polution
				assert(message.value ~= nil)
				fsm.blackboard[message.id] = message.value
			end
		else
			if message_id == cmn.msgtype_trigger then
				if message.id == cmn.trigger_attack then
					fsm:attack()
				elseif message.id == cmn.trigger_damage then
					fsm:takedamage()
				elseif message.id == cmn.trigger_roll then
					fsm:roll()
				end
			end
			local messagehandler = "onmessage" .. fsm.current
			if fsm[messagehandler] ~= nil then
				fsm[messagehandler](message_id, message, sender)
			end
		end
	end

	return fsm
end

return M