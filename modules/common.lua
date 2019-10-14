local M = {}

-- Message types
M.msgtype_param			= hash("msgtype_param")
M.msgtype_trigger		= hash("msgtype_trigger")
M.msgtype_tag			= hash("msgtype_tag")
M.msgtype_check_tag		= hash("msgtype_check_tag")
M.msgtype_input			= hash("msgtype_input")
M.msgtype_anim_event	= hash("msgtype_anim_event")

-- Params
-- /Updates each frame/
M.param_move 			= hash("param_move") -- float [-1; 1]
M.param_vvel			= hash("param_vvel") -- vertical velocity
M.param_attack_input	= hash("param_attack_input") -- true / false
M.param_roll_input		= hash("param_roll_input") -- true / false

-- Triggers
-- /Eventually fired/
M.trigger_attack		= hash("trigger_attack")
M.trigger_damage		= hash("trigger_damage")
M.trigger_jump			= hash("trigger_jump")
M.trigger_roll			= hash("trigger_roll")

-- Tags
-- /Activate/deactivate/
M.tag_grounded 			= hash("tag_grounded")
M.tag_hurt 				= hash("tag_hurt")
M.tag_dead				= hash("tag_dead")
M.tag_attack 			= hash("tag_attack")
M.tag_roll				= hash("tag_roll")

-- Input
M.input_left			= hash("left")
M.input_right			= hash("right")
M.input_attack			= hash("attack")
M.input_jump			= hash("jump")
M.input_roll			= hash("roll")

-- Anim events
M.anim_started			= hash("anim_started")
M.anim_finished			= hash("anim_finished")
M.anim_interrupted		= hash("anim_interrupted")

return M