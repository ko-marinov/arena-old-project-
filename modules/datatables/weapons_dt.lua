-- Create new weapon stats
local function _(prepTime, relaxTime, animSet, animNum, hitLogic)
	return {
		prepTime	= prepTime,			-- time before hit
		relaxTime	= relaxTime,		-- time after hit and before next hit
		animSet 	= animSet,			-- set of owner's animations
		animNum 	= animNum,			-- number of animations in animation set
		hitLogic	= hitLogic			-- actions to do on hit: function(relaxTransitionClbk, fsm)
	}
end

------------------------------------------------------------------------------------------
--     Weapon Stats Data Table
------------------------------------------------------------------------------------------
local weaponsDataTable = {
	--- SWORD ---	
	[hash("sword")] = _(0.2,									-- time before hit
				0.2,									-- time after hit and before next hit
				"sword",								-- set of owner's animations
				3,										-- number of animations in animation set
				function(relaxTransitionClbk, fsm)		-- actions to do on hit
					local timerClbck = function(self, handle, time_elapsed)
						msg.post(".", "stop_damage")
						fsm[relaxTransitionClbk](fsm)
					end

					timer.delay(0.08, false, timerClbck)
					msg.post(".", "start_damage")
				end),

	--- LANCE ---
	[hash("lance")] = _(0.3,									-- time before hit
				0.3,									-- time after hit and before next hit
				"sword",								-- set of owner's animations
				3,										-- number of animations in animation set
				function(relaxTransitionClbk, fsm)		-- actions to do on hit
					local timerClbck = function(self, handle, time_elapsed)
						msg.post(".", "stop_damage")
						fsm[relaxTransitionClbk](fsm)
					end
									timer.delay(0.08, false, timerClbck)
					msg.post(".", "start_damage")
				end),

	--- BOW ---
	[hash("bow")] = _(0.5,									-- time before hit
				0.1,									-- time after hit and before next hit
				"sword",								-- set of owner's animations
				3,										-- number of animations in animation set
				function(relaxTransitionClbk, fsm)		-- actions to do on hit
					local timerClbck = function(self, handle, time_elapsed)
						msg.post(".", "stop_damage")
						fsm[relaxTransitionClbk](fsm)
					end

					timer.delay(0.08, false, timerClbck)
					msg.post(".", "start_damage")
				end)
}

return weaponsDataTable