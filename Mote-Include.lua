-------------------------------------------------------------------------------------------------------------------
-- Common variables and functions to be included in job scripts.
-- Include this file in the get_sets() function with the command:
-- include('Mote-Include.lua')
--
-- You then MUST run init_include()
--
-- It should be the first command in the get_sets() function, but must at least be executed before
-- any included vars are referenced.
--
-- Included variables and functions are considered to be at the same scope level as
-- the job script itself, and can be used as such.
--
-- This script has access to any vars defined at the job lua's scope, such as player and world.
-------------------------------------------------------------------------------------------------------------------

-- Last Modified: 1/10/2014 12:01:00 AM

-- Define the include module as a table (clean, forwards compatible with lua 5.2).
local MoteInclude = {}


-------------------------------------------------------------------------------------------------------------------
-- Initialization function that defines variables to be used.
-- These are accessible at the including job lua script's scope.
-------------------------------------------------------------------------------------------------------------------

function MoteInclude.init_include()
	-- Var for tracking state values
	state = {}
	
	-- General melee offense/defense modes, allowing for hybrid set builds, as well as idle/resting/weaponskill.
	state.OffenseMode     = 'Normal'
	state.DefenseMode     = 'Normal'
	state.WeaponskillMode = 'Normal'
	state.CastingMode     = 'Normal'
	state.IdleMode        = 'Normal'
	state.RestingMode     = 'Normal'
	
	-- All-out defense state, either physical or magical
	state.Defense = {}
	state.Defense.Active       = false
	state.Defense.Type         = 'Physical'
	state.Defense.PhysicalMode = 'PDT'
	state.Defense.MagicalMode  = 'MDT'

	state.Kiting               = false
	state.MaxWeaponskillDistance = 0
	
	state.SelectNPCTargets     = false
	state.PCTargetMode         = 'default'
	
	
	-- Vars for specifying valid mode values.
	-- Defaults here are just for example. Set them properly in each job file.
	options = {}
	options.OffenseModes = {'Normal', 'Acc','Crit'}
	options.DefenseModes = {'Normal', 'PDT', 'Evasion','Counter'}
	options.WeaponskillModes = {'Normal', 'PDT', 'Evasion','Counter'}
	options.CastingModes = {'Normal'}
	options.IdleModes = {'Normal'}
	options.RestingModes = {'Normal'}
	options.PhysicalDefenseModes = {'PDT', 'Evasion'}
	options.MagicalDefenseModes = {'MDT', 'Resist'}

	options.TargetModes = {'default', 'stpc', 'stpt', 'stal'}
	

	-- Spell mappings to describe a 'type' of spell.  Used when searching for valid sets.
	classes = {}
	-- Basic spell mappings are based on common spell series.
	-- EG: 'Cure' for Cure, Cure II, Cure III, Cure IV, Cure V, or Cure VI.
	classes.spellMappings = get_spell_mappings()
	-- List of spells and spell maps that don't benefit from greater skill (though
	-- they may benefit from spell-specific augments, such as improved regen or refresh).
	-- Spells that fall under this category will be skipped when searching for
	-- spell.skill sets.
	classes.NoSkillSpells = S{
		'Haste', 'Refresh', 'Regen', 'Protect', 'Protectra', 'Shell', 'Shellra',
		'Raise', 'Reraise','Cursna'}
	-- Custom, job-defined class, like the generic spell mappings.
	-- Takes precedence over default spell maps.
	-- Is reset at the end of each spell casting cycle (ie: at the end of aftercast).
	classes.CustomClass = nil
	-- Custom groups used for defining melee and idle sets.  Persists long-term.
	classes.CustomMeleeGroups = L{}
	classes.CustomIdleGroups = L{}
	
	-- Var for use in melee set construction.
	TPWeapon = 'Normal'
	
	-- Special var for displaying sets at certain cast times.
	showSet = nil
		
	-- Display text mapping.
	on_off_names = {[true] = 'on', [false] = 'off'}

	-- Stuff for handling self commands.
	-- The below map certain predefined commands to internal functions.
	selfCommands = {
		['toggle']=handle_toggle,
		['activate']=handle_activate,
		['cycle']=handle_cycle,
		['set']=handle_set,
		['reset']=handle_reset,
		['update']=handle_update,
		['showset']=handle_show_set,
		['naked']=handle_naked,
		['test']=handle_test}
	

	-- Subtables within the sets table that we expect to exist, and are annoying to have to
	-- define within each individual job file.  We can define them here to make sure we don't
	-- have to check for existence.  The job file should be including this before defining
	-- any sets, so any changes it makes will override these anyway.
	sets.precast = {}
	sets.precast.FC = {}
	sets.precast.JA = {}
	sets.precast.WS = {}
	sets.midcast = {}
	sets.idle = {}
	sets.resting = {}
	sets.engaged = {}
	sets.defense = {}
	sets.buff = {}
	

	-- Set specialized groupings of world zones.
	areas = {}
	-- City areas for town gear and behavior.
	areas.Cities = S{"RU'LUDE GARDENS", 'UPPER JEUNO','LOWER JEUNO','PORT JEUNO',
		'PORT WINDURST','WINDURST WATERS','WINDURST WOODS','WINDURST WALLS','HEAVENS TOWER',
		"PORT SAN D'ORIA","NORTHERN SAN D'ORIA","SOUTHERN SAN D'ORIA",
		'PORT BASTOK','BASTOK MARKETS','BASTOK MINES','METALWORKS',
		'AHT URHGAN WHITEGATE','TAVANAZIAN SAFEHOLD','NASHMAU',
		'SELBINA','MHAURA','NORG','EASTERN ADOULIN','WESTERN ADOULIN'}
	-- Adoulin areas, where Ionis will grant special stat bonuses.
	areas.Adoulin = S{'YAHSE HUNTING GROUNDS', 'CEIZAK BATTLEGROUNDS', 'FORET DE HENNETIEL','MORIMAR BASALT FIELDS',
		'YORCIA WEALD','YORCIA WEALD [U]', 'CIRDAS CAVERNS','CIRDAS CAVERNS [U]',
		'MARJAMI RAVINE','KAMIHR DRIFTS', 'SIH GATES','MOH GATES','DHO GATES','WOH GATES','RALA WATERWAYS'}


	-- Special gear info that may be useful across jobs.
	gear = {}
	
	gear.Obi = {}
	gear.Obi.Light = "Korin Obi"
	--gear.Obi.Dark = "Anrin Obi"
	gear.Obi.Fire = "Karin Obi"
	gear.Obi.Ice = "Hyorin Obi"
	--gear.Obi.Wind = "Furin Obi"
	--gear.Obi.Earth = "Dorin Obi"
	gear.Obi.Lightning = "Rairin Obi"
	--gear.Obi.Water = "Suirin Obi"

	gear.Staff = {}
	gear.Staff.HMP = 'Chatoyant Staff'
	gear.Staff.PDT = 'Earth Staff'


	-- Other general vars.  Set whatever's convenient for your job luas.
	
end


-------------------------------------------------------------------------------------------------------------------
-- Generalized functions for handling precast/midcast/aftercast for player-initiated actions.
-- This depends on proper set naming.
-- Each job can override any amount of these general functions using job_xxx() hooks.
-------------------------------------------------------------------------------------------------------------------

-- Pretarget is called when GearSwap intercepts the original text input, but
-- before the game has done any processing on it.  In particular, it hasn't
-- initiated target selection for <st*> target types.
-- This is the only function where it will be valid to use change_target().
function MoteInclude.pretarget(spell,action)
	local spellMap = classes.spellMappings[spell.english]

	-- init a new eventArgs
	local eventArgs = {handled = false, cancel = false}

	-- Allow the job to handle it.
	if job_pretarget then
		job_pretarget(spell, action, spellMap, eventArgs)
	end

	if eventArgs.cancel then
		cancel_spell()
		return
	end
	
	-- If the job didn't handle things themselves, continue..
	if not eventArgs.handled then
		-- Handle optional target conversion.
		auto_change_target(spell, action, spellMap)
	end
end


-- Called after the text command has been processed (and target selected), but
-- before the packet gets pushed out.
-- Equip any gear that should be on before the spell or ability is used.
-- Define the set to be equipped at this point in time based on the type of action.
function MoteInclude.precast(spell, action)
	-- Get the spell mapping, since we'll be passing it to various functions and checks.
	local spellMap = classes.spellMappings[spell.english]
	
	-- init a new eventArgs
	local eventArgs = {handled = false, cancel = false}

	-- Allow jobs to have first shot at setting up the precast gear.
	if job_precast then
		job_precast(spell, action, spellMap, eventArgs)
	end
	
	if eventArgs.cancel then
		cancel_spell()
		return
	end

	-- Perform default equips if the job didn't handle it.
	if not eventArgs.handled then
		equip(get_default_precast_set(spell, action, spellMap, eventArgs))
	end
	
	-- Allow followup code to add to what was done here
	if job_post_precast then
		job_post_precast(spell, action, spellMap, eventArgs)
	end
end


-- Called immediately after precast() so that we can build the midcast gear set which
-- will be sent out at the same time (packet contains precastgear:action:midcastgear).
-- Midcast gear selected should be for potency, recast, etc.  It should take effect
-- regardless of the spell cast speed.
function MoteInclude.midcast(spell,action)
	-- If we have showSet active for precast, don't try to equip midcast gear.
	if showSet == 'precast' then
		add_to_chat(122, 'Show Sets: Stopping at precast.')
		return
	end

	local spellMap = classes.spellMappings[spell.english]

	-- init a new eventArgs
	local eventArgs = {handled = false}
	
	-- Allow jobs to override this code
	if job_midcast then
		job_midcast(spell, action, spellMap, eventArgs)
	end

	-- Perform default equips if the job didn't handle it.
	if not eventArgs.handled then
		equip(get_default_midcast_set(spell, action, spellMap, eventArgs))
	end
	
	-- Allow followup code to add to what was done here
	if job_post_midcast then
		job_post_midcast(spell, action, spellMap, eventArgs)
	end
end




-- Called when an action has been completed (eg: spell finished casting, or failed to cast).
function MoteInclude.aftercast(spell,action)
	-- If we have showSet active for precast or midcast, don't try to equip aftercast gear.
	if showSet == 'midcast' then
		add_to_chat(122, 'Show Sets: Stopping at midcast.')
		return
	elseif showSet == 'precast' then
		return
	end
	
	-- Ignore the Unknown Interrupt
	if spell.name == 'Unknown Interrupt' then
		--add_to_chat(123, 'aftercast trace: Unknown Interrupt.  interrupted='..tostring(spell.interrupted))
		return
	end

	local spellMap = classes.spellMappings[spell.english]

	-- init a new eventArgs
	local eventArgs = {handled = false}

	-- Allow jobs to override this code
	if job_aftercast then
		job_aftercast(spell, action, spellMap, eventArgs)
	end

	if not eventArgs.handled then
		if spell.interrupted then
			-- Wait a half-second to update so that aftercast equip will actually be worn.
			windower.send_command('wait 0.6;gs c update')
		else
			handle_equipping_gear(player.status)
		end
	end

	-- Allow followup code to add to what was done here
	if job_post_aftercast then
		job_post_aftercast(spell, action, spellMap, eventArgs)
	end
	
	-- Reset after all possible precast/midcast/aftercast/job-specific usage of the value.
	classes.CustomClass = nil
end


function MoteInclude.pet_midcast(spell,action)
	-- If we have showSet active for precast, don't try to equip midcast gear.
	if showSet == 'precast' then
		add_to_chat(122, 'Show Sets: Stopping at precast.')
		return
	end

	local spellMap = classes.spellMappings[spell.english]

	-- init a new eventArgs
	local eventArgs = {handled = false}
	
	-- Allow jobs to override this code
	if job_pet_midcast then
		job_pet_midcast(spell, action, spellMap, eventArgs)
	end

	-- Perform default equips if the job didn't handle it.
	if not eventArgs.handled then
		equip(get_default_pet_midcast_set(spell, action, spellMap, eventArgs))
	end
	
	-- Allow followup code to add to what was done here
	if job_post_pet_midcast then
		job_post_pet_midcast(spell, action, spellMap, eventArgs)
	end
end

function MoteInclude.pet_aftercast(spell,action)
	-- If we have showSet active for precast or midcast, don't try to equip aftercast gear.
	if showSet == 'midcast' then
		add_to_chat(122, 'Show Sets: Stopping at midcast.')
		return
	elseif showSet == 'precast' then
		return
	end

	local spellMap = classes.spellMappings[spell.english]

	-- init a new eventArgs
	local eventArgs = {handled = false}
	
	-- Allow jobs to override this code
	if job_pet_aftercast then
		job_pet_aftercast(spell, action, spellMap, eventArgs)
	end

	if not eventArgs.handled then
		if spell.interrupted then
			-- Wait a half-second to update so that aftercast equip will actually be worn.
			windower.send_command('wait 0.6;gs c update')
		else
			handle_equipping_gear(player.status)
		end
	end
	
	-- Allow followup code to add to what was done here
	if job_post_pet_aftercast then
		job_post_pet_aftercast(spell, action, spellMap, eventArgs)
	end
	
	-- Reset after all possible precast/midcast/aftercast/job-specific usage of the value.
	classes.CustomClass = nil
end

-------------------------------------------------------------------------------------------------------------------
-- Hooks for non-action events.
-------------------------------------------------------------------------------------------------------------------

-- Called when the player's status changes.
function MoteInclude.status_change(newStatus, oldStatus)
	-- init a new eventArgs
	local eventArgs = {handled = false}

	-- Allow jobs to override this code
	if job_status_change then
		job_status_change(newStatus, oldStatus, eventArgs)
	end

	
	-- Create a timer when we gain weakness.  Remove it when weakness is gone.
	if oldStatus == 'Dead' then
		send_command('timers create "Weakness" 300 up abilities/00255.png')
	end

	-- Equip default gear if not handled by the job.
	if not eventArgs.handled then
		handle_equipping_gear(newStatus)
	end
end


-- Called when the player's status changes.
function MoteInclude.pet_status_change(newStatus, oldStatus)
	-- init a new eventArgs
	local eventArgs = {handled = false}

	-- Allow jobs to override this code
	if job_pet_status_change then
		job_pet_status_change(newStatus, oldStatus, eventArgs)
	end

	-- Equip default gear if not handled by the job.
	if not eventArgs.handled then
		handle_equipping_gear(player.status, newStatus)
	end
end


-- Called when a player gains or loses a buff.
-- buff == buff gained or lost
-- gain == true if the buff was gained, false if it was lost.
function MoteInclude.buff_change(buff, gain)
	-- Global actions on buff effects
	
	-- Create a timer when we gain weakness.  Remove it when weakness is gone.
	if buff == 'Weakness' then
		if not gain then
			send_command('timers delete "Weakness"')
		end
	end

	-- Any job-specific handling.
	if job_buff_change then
		job_buff_change(buff, gain)
	end
end


-------------------------------------------------------------------------------------------------------------------
-- Generalized functions for selecting and equipping gear sets.
-------------------------------------------------------------------------------------------------------------------

-- Central point to call to equip gear based on status.
-- Status - Player status that we're using to define what gear to equip.
function MoteInclude.handle_equipping_gear(playerStatus, petStatus)
	-- init a new eventArgs
	local eventArgs = {handled = false}

	-- Allow jobs to override this code
	if job_handle_equipping_gear then
		job_handle_equipping_gear(playerStatus, eventArgs)
	end

	-- Equip default gear if job didn't handle it.
	if not eventArgs.handled then
		equip_gear_by_status(playerStatus)
	end
end


-- Function to wrap logic for equipping gear on aftercast, status change, or user update.
-- @param status : The current or new player status that determines what sort of gear to equip.
function MoteInclude.equip_gear_by_status(status)
	if _global.debug_mode then add_to_chat(123,'Debug: Equip gear for status ['..tostring(status)..'], HP='..tostring(player.hp)) end
	
	-- If status not defined, treat as idle.
	-- Be sure to check for positive HP to make sure they're not dead.
	if status == nil or status == '' then
		if player.hp > 0 then
			equip(get_current_idle_set())
		end
	elseif status == 'Idle' then
		equip(get_current_idle_set())
	elseif status == 'Engaged' then
		equip(get_current_melee_set())
	elseif status == 'Resting' then
		equip(get_current_resting_set())
	end
end


-------------------------------------------------------------------------------------------------------------------
-- Functions for constructing default sets.
-------------------------------------------------------------------------------------------------------------------

-- Get the default precast gear set.
function MoteInclude.get_default_precast_set(spell, action, spellMap, eventArgs)
	local equipSet = {}

	if spell.action_type == 'Magic' then
		-- Call this to break 'precast.FC' into a proper set.
		equipSet = sets.precast.FC

		-- Set determination ordering:
		-- Custom class
		-- Class mapping
		-- Specific spell name
		-- Skill
		-- Spell type
		if classes.CustomClass and equipSet[classes.CustomClass] then
			equipSet = equipSet[classes.CustomClass]
		elseif equipSet[spell.english] then
			equipSet = equipSet[spell.english]
		elseif spellMap and equipSet[spellMap] then
			equipSet = equipSet[spellMap]
		elseif equipSet[spell.skill] then
			equipSet = equipSet[spell.skill]
		elseif equipSet[spell.type] then
			equipSet = equipSet[spell.type]
		end
		
		-- Check for specialized casting modes for any given set selection.
		if equipSet[state.CastingMode] then
			equipSet = equipSet[state.CastingMode]
		end

		-- Magian staves with fast cast on them
		if sets.precast.FC[tostring(spell.element)] then
			equipSet = set_combine(equipSet, baseSet[tostring(spell.element)])
		end
	elseif spell.type:lower() == 'weaponskill' then
		local modeToUse = state.WeaponskillMode
		local job_wsmode = nil
		
		-- Allow the job file to specify a weaponskill mode
		if get_job_wsmode then
			job_wsmode = get_job_wsmode(spell, action, spellMap)
		end

		-- If the job file returned a weaponskill mode, use that.
		if job_wsmode then
			modeToUse = job_wsmode
		elseif state.WeaponskillMode == 'Normal' then
			-- If a particular weaponskill mode isn't specified, see if we have a weaponskill mode
			-- corresponding to the current offense mode.  If so, use that.
			if state.OffenseMode ~= 'Normal' and S(options.WeaponskillModes)[state.OffenseMode] then
				modeToUse = state.OffenseMode
			end
		end
		
		if sets.precast.WS[spell.english] then
			if sets.precast.WS[spell.english][modeToUse] then
				equipSet = sets.precast.WS[spell.english][modeToUse]
			else
				equipSet = sets.precast.WS[spell.english]
			end
		elseif classes.CustomClass and sets.precast.WS[classes.CustomClass] then
			if sets.precast.WS[classes.CustomClass][modeToUse] then
				equipSet = sets.precast.WS[classes.CustomClass][modeToUse]
			else
				equipSet = sets.precast.WS[classes.CustomClass]
			end
		else
			if sets.precast.WS[modeToUse] then
				equipSet = sets.precast.WS[modeToUse]
			else
				equipSet = sets.precast.WS
			end
		end
	elseif spell.type:lower() == 'jobability' then
		if sets.precast.JA[spell.english] then
			equipSet = sets.precast.JA[spell.english]
		end
	-- All other types, such as Waltz, Jig, Scholar, etc.
	elseif sets.precast[spell.type] then
		if sets.precast[spell.type][spell.english] then
			equipSet = sets.precast[spell.type][spell.english]
		else
			equipSet = sets.precast[spell.type]
		end
	end
	
	return equipSet
end


-- Get the default midcast gear set.
function MoteInclude.get_default_midcast_set(spell, action, spellMap, eventArgs)
	local equipSet = {}

	if spell.action_type == 'Magic' then
		-- Set selection ordering:
		-- Custom class
		-- Specific spell name
		-- Class mapping
		-- Skill
		-- Spell type
		if classes.CustomClass and sets.midcast[classes.CustomClass] then
			equipSet = sets.midcast[classes.CustomClass]
		elseif sets.midcast[spell.english] then
			equipSet = sets.midcast[spell.english]
		elseif spellMap and sets.midcast[spellMap] then
			equipSet = sets.midcast[spellMap]
		elseif sets.midcast[spell.skill] and
			not (classes.NoSkillSpells[spell.english] or classes.NoSkillSpells[spellMap]) then
			equipSet = sets.midcast[spell.skill]
		elseif sets.midcast[spell.type] then
			equipSet = sets.midcast[spell.type]
		else
			equipSet = sets.midcast
		end

		-- Check for specialized casting modes for any given set selection.
		if equipSet[state.CastingMode] then
			equipSet = equipSet[state.CastingMode]
		end
	end
	
	return equipSet
end


-- Get the default pet midcast gear set.
function MoteInclude.get_default_pet_midcast_set(spell, action, spellMap, eventArgs)
	local equipSet = {}

	-- TODO: examine possible values in pet actions
	
	-- Set selection ordering:
	-- Custom class
	-- Specific spell name
	-- Class mapping
	-- Skill
	-- Spell type
	if sets.midcast.Pet then
		if classes.CustomClass and sets.midcast.Pet[classes.CustomClass] then
			equipSet = sets.midcast.Pet[classes.CustomClass]
		elseif sets.midcast.Pet[spell.english] then
			equipSet = sets.midcast.Pet[spell.english]
		elseif spellMap and sets.midcast.Pet[spellMap] then
			equipSet = sets.midcast.Pet[spellMap]
		elseif sets.midcast.Pet[spell.skill] then
			equipSet = sets.midcast.Pet[spell.skill]
		elseif sets.midcast.Pet[spell.type] then
			equipSet = sets.midcast.Pet[spell.type]
		else
			equipSet = sets.midcast.Pet
		end
	end

	-- Check for specialized casting modes for any given set selection.
	if equipSet[state.CastingMode] then
		equipSet = equipSet[state.CastingMode]
	end
	
	return equipSet
end



-- Returns the appropriate idle set based on current state.
function MoteInclude.get_current_idle_set()
	local idleScope = ''
	local idleSet = sets.idle

	if buffactive.weakness then
		idleScope = 'Weak'
	elseif areas.Cities[world.area] then
		idleScope = 'Town'
	else
		idleScope = 'Field'
	end
	
	if _global.debug_mode then add_to_chat(123,'Debug: Idle scope for '..world.area..' is '..idleScope) end

	if idleSet[idleScope] then
		idleSet = idleSet[idleScope]
	end

	if idleSet[state.IdleMode] then
		idleSet = idleSet[state.IdleMode]
	end

	for i = 1,#classes.CustomIdleGroups do
		if idleSet[classes.CustomIdleGroups[i]] then
			idleSet = idleSet[classes.CustomIdleGroups[i]]
		end
	end
	
	idleSet = apply_defense(idleSet)
	idleSet = apply_kiting(idleSet)
	
	if customize_idle_set then
		idleSet = customize_idle_set(idleSet)
	end

	--if _global.debug_mode then print_set(idleSet, 'Final Idle Set') end
	
	return idleSet
end


-- Returns the appropriate melee set based on current state.
-- Set construction order (all sets after sets.engaged are optional):
--   sets.engaged[classes.CustomMeleeGroups (any number)][TPWeapon][state.OffenseMode][state.DefenseMode]
function MoteInclude.get_current_melee_set()
	local meleeSet = sets.engaged
	
	for i = 1,#classes.CustomMeleeGroups do
		if meleeSet[classes.CustomMeleeGroups[i]] then
			meleeSet = meleeSet[classes.CustomMeleeGroups[i]]
		end
	end
	
	if meleeSet[TPWeapon] then
		meleeSet = meleeSet[TPWeapon]
	end
	
	if meleeSet[state.OffenseMode] then
		meleeSet = meleeSet[state.OffenseMode]
	end
	
	if meleeSet[state.DefenseMode] then
		meleeSet = meleeSet[state.DefenseMode]
	end
	
	meleeSet = apply_defense(meleeSet)
	meleeSet = apply_kiting(meleeSet)

	if customize_melee_set then
		meleeSet = customize_melee_set(meleeSet)
	end

	--if _global.debug_mode then print_set(meleeSet, 'Melee set') end
	
	return meleeSet
end


-- Returns the appropriate resting set based on current state.
function MoteInclude.get_current_resting_set()
	local restingSet = {}
	
	if sets.resting[state.RestingMode] then
		restingSet = sets.resting[state.RestingMode]
	else
		restingSet = sets.resting
	end

	--if _global.debug_mode then print_set(restingSet, 'Resting Set') end
	
	return restingSet
end


-- Function to apply any active defense set on top of the supplied set
-- @param baseSet : The set that any currently active defense set will be applied on top of. (gear set table)
function MoteInclude.apply_defense(baseSet)
	if state.Defense.Active then
		local defenseSet = {}
		local defMode = ''
		
		if state.Defense.Type == 'Physical' then
			defMode = state.Defense.PhysicalMode
			
			if sets.defense[state.Defense.PhysicalMode] then
				defenseSet = sets.defense[state.Defense.PhysicalMode]
			else
				defenseSet = sets.defense
			end
		else
			defMode = state.Defense.MagicalMode

			if sets.defense[state.Defense.MagicalMode] then
				defenseSet = sets.defense[state.Defense.MagicalMode]
			else
				defenseSet = sets.defense
			end
		end
		
		baseSet = set_combine(baseSet, defenseSet)
	end
	
	return baseSet
end


-- Function to add kiting gear on top of the base set if kiting state is true.
-- @param baseSet : The set that the kiting gear will be applied on top of. (gear set table)
function MoteInclude.apply_kiting(baseSet)
	if state.Kiting then
		if sets.Kiting then
			baseSet = set_combine(baseSet, sets.Kiting)
		end
	end
	
	return baseSet
end


-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------
-- General functions for manipulating state values.
-- Only specifically handles state and such that we've defined within this include.
-------------------------------------------------------------------------------------------------------------------

-- Routing function for general known self_commands.
-- Handles splitting the provided command line up into discrete words, for the other functions to use.
function MoteInclude.self_command(commandArgs)
	local commandArgs = commandArgs
	if type(commandArgs) == 'string' then
		commandArgs = split(commandArgs, ' ')
		if #commandArgs == 0 then
			return
		end
	end
	
	-- init a new eventArgs
	local eventArgs = {handled = false}

	-- Allow jobs to override this code
	if job_self_command then
		job_self_command(commandArgs, eventArgs)
	end

	if not eventArgs.handled then
		-- Of the original command message passed in, remove the first word from
		-- the list (it will be used to determine which function to call), and
		-- send the remaining words are parameters for the function.
		local handleCmd = table.remove(commandArgs, 1)
		
		if selfCommands[handleCmd] then
			selfCommands[handleCmd](commandArgs)
		end
	end
end


-- Individual handling of self-commands


-- Handle toggling specific vars that we know of.
-- Valid toggles: Defense, Kiting
-- Returns true if a known toggle was handled.  Returns false if not.
-- User command format: gs c toggle [field]
function MoteInclude.handle_toggle(cmdParams)
	if #cmdParams > 0 then
		-- identifier for the field we're toggling
		local toggleField = cmdParams[1]:lower()
		local toggleDesc = ''
		local toggleVal
		
		if toggleField == 'defense' then
			state.Defense.Active = not state.Defense.Active
			toggleVal = state.Defense.Active
			toggleDesc = state.Defense.Type
			if state.Defense.Type == 'Physical' then
				toggleDesc = 'Physical defense ('..state.Defense.PhysicalMode..')'
			else
				toggleDesc = 'Magical defense ('..state.Defense.MagicalMode..')'
			end
		elseif toggleField == 'kite' or toggleField == 'kiting' then
			state.Kiting = not state.Kiting
			toggleVal = state.Kiting
			toggleDesc = 'Kiting'
		elseif toggleField == 'target' then
			state.SelectNPCTargets = not state.SelectNPCTargets
			toggleVal = state.SelectNPCTargets
			toggleDesc = 'NPC targetting'
		else
			if _global.debug_mode then add_to_chat(123,'Unknown toggle field: '..toggleField) end
			return false
		end

		if job_state_change then
			job_state_change(toggleDesc, toggleVal)
		end

		add_to_chat(122,toggleDesc..' is now '..on_off_names[toggleVal]..'.')
	else
		if _global.debug_mode then add_to_chat(123,'--handle_toggle parameter failure: field not specified') end
		return false
	end
	
	handle_update({'auto'})
	return true
end


-- Function to handle turning on particular states, while possibly also setting a mode value.
-- User command format: gs c activate [field]
function MoteInclude.handle_activate(cmdParams)
	if #cmdParams > 0 then
		activateState = cmdParams[1]:lower()
		local activateDesc = ''
		
		if activateState == 'physicaldefense' then
			state.Defense.Active = true
			state.Defense.Type = 'Physical'
			activateDesc = 'Physical defense ('..state.Defense.PhysicalMode..')'
		elseif activateState == 'magicaldefense' then
			state.Defense.Active = true
			state.Defense.Type = 'Magical'
			activateDesc = 'Magical defense ('..state.Defense.MagicalMode..')'
		elseif activateState == 'kite' or activateState == 'kiting' then
			state.Kiting = true
			activateDesc = 'Kiting'
		elseif activateState == 'target' then
			state.SelectNPCTargets = true
			activateDesc = 'NPC targetting'
		else
			if _global.debug_mode then add_to_chat(123,'--handle_activate unknown state to activate: '..activateState) end
			return false
		end

		-- Notify the job of the change.
		if job_state_change then
			job_state_change(activateDesc, true)
		end

		-- Display what got changed to the user.
		add_to_chat(122,activateDesc..' is now on.')
	else
		if _global.debug_mode then add_to_chat(123,'--handle_activate parameter failure: field not specified') end
		return false
	end
	
	handle_update({'auto'})
	return true
end


-- Handle cycling through the options for specific vars that we know of.
-- Valid fields: OffenseMode, DefenseMode, WeaponskillMode, IdleMode, RestingMode, CastingMode, PhysicalDefenseMode, MagicalDefenseMode
-- All fields must end in 'Mode'
-- Returns true if a known toggle was handled.  Returns false if not.
-- User command format: gs c cycle [field]
function MoteInclude.handle_cycle(cmdParams)
	if #cmdParams > 0 then
		-- identifier for the field we're toggling
		local paramField = cmdParams[1]:lower()

		if paramField:endswith('mode') then
			-- Remove 'mode' from the end of the string
			local modeField = paramField:sub(1,#paramField-4)
			-- Convert WS to Weaponskill
			if modeField == "ws" then
				modeField = "weaponskill"
			end
			-- Capitalize the field (for use on output display)
			modeField = modeField:gsub("%f[%a]%a", string.upper)

			-- Get the options.XXXModes table, and the current state mode for the mode field.
			local modeTable, currentValue = get_mode_table(modeField)

			if not modeTable then
				if _global.debug_mode then add_to_chat(123,'Unknown mode : '..modeField..'.') end
				return false
			end

			-- Get the index of the current mode.  'Normal' or undefined is treated as index 0.
			local invertedTable = invert_table(modeTable)
			local index = 0
			if invertedTable[currentValue] then
				index = invertedTable[currentValue]
			end
			
			-- Increment to the next index in the available modes.
			index = index + 1
			if index > #modeTable then
				index = 1
			end
			
			-- Determine the new mode value based on the index.
			local newModeValue = ''
			if index and modeTable[index] then
				newModeValue = modeTable[index]
			else
				newModeValue = 'Normal'
			end
			
			-- And save that to the appropriate state field.
			set_mode(modeField, newModeValue)
			
			if job_state_change then
				job_state_change(modeField..'Mode', newModeValue)
			end
			
			-- Display what got changed to the user.
			add_to_chat(122,modeField..' mode is now '..newModeValue..'.')
		else
			if _global.debug_mode then add_to_chat(123,'Invalid cycle field (does not end in "mode"): '..paramField) end
			return false
		end
	else
		if _global.debug_mode then add_to_chat(123,'--handle_cycle parameter failure: field not specified') end
		return false
	end
	handle_update({'auto'})
	return true
end

-- Function to set various states to specific values directly.
-- User command format: gs c set [field] [value]
function MoteInclude.handle_set(cmdParams)
	if #cmdParams > 1 then
		-- identifier for the field we're setting
		local field = cmdParams[1]
		local lowerField = field:lower()
		local setField = cmdParams[2]
		local fieldDesc = ''
		
		
		-- Check if we're dealing with a boolean
		if T{'on', 'off', 'true', 'false'}:contains(setField) then
			local setValue = T{'on', 'true'}:contains(setField)
			
			if lowerField == 'defense' then
				state.Defense.Active = setValue
				if state.Defense.Type == 'Physical' then
					fieldDesc = 'Physical defense ('..state.Defense.PhysicalMode..')'
				else
					fieldDesc = 'Magical defense ('..state.Defense.MagicalMode..')'
				end
			elseif lowerField == 'kite' or lowerField == 'kiting' then
				state.Kiting = setValue
				fieldDesc = 'Kiting'
			elseif lowerField == 'target' then
				state.SelectNPCTargets = setValue
				fieldDesc = 'NPC targetting'
			else
				if _global.debug_mode then add_to_chat(123,'Unknown field to set: '..field) end
				return false
			end


			-- Notify the job of the change.
			if job_state_change then
				job_state_change(fieldDesc, setValue)
			end
	
			-- Display what got changed to the user.
			add_to_chat(122,fieldDesc..' is now '..on_off_names[setValue]..'.')

		-- Or if we're dealing with a mode setting
		elseif lowerField:endswith('mode') then
			-- Remove 'mode' from the end of the string
			modeField = lowerField:sub(1,#lowerField-4)
			-- Convert WS to Weaponskill
			if modeField == "ws" then
				modeField = "weaponskill"
			end
			-- Capitalize the field (for use on output display)
			modeField = modeField:gsub("%a", string.upper, 1)
			
			-- Get the options.XXXModes table, and the current state mode for the mode field.
			local modeTable, currentValue = get_mode_table(modeField)
			
			if not modeTable or not modeTable[setField] then
				if _global.debug_mode then add_to_chat(123,'Unknown mode value: '..setField..' for '..modeField..' mode.') end
				return false
			end
			
			-- And save that to the appropriate state field.
			set_mode(modeField, setField)

			-- Notify the job script of the change.
			if job_state_change then
				job_state_change(modeField, setField)
			end
			
			-- Display what got changed to the user.
			add_to_chat(122,modeField..' mode is now '..setField..'.')

		-- Or issueing a command where the user may not provide the value
		elseif lowerField == 'distance' then
			if setField then
				local possibleDistance = tonumber(setField)
				if possibleDistance ~= nil then
					state.MaxWeaponskillDistance = possibleDistance
				else
					add_to_chat(123,'Invalid distance value: '..setField)
				end
				
				-- set max weaponskill distance to the current distance the player is from the mob.

				add_to_chat(123,'Using max weaponskill distance is not implemented right now.')
			else
				-- Get current player distance and use that
				add_to_chat(123,'TODO: get player distance.')
			end
		else
			if _global.debug_mode then add_to_chat(123,'Unknown set handling: '..field..' : '..setField) end
			return false
		end
	else
		if _global.debug_mode then add_to_chat(123,'--handle_set parameter failure: insufficient fields') end
		return false
	end
	
	handle_update({'auto'})
	return true
end


-- Function to turn off togglable features, or reset values to their defaults.
-- User command format: gs c reset [field]
function MoteInclude.handle_reset(cmdParams)
	if #cmdParams > 0 then
		resetState = cmdParams[1]:lower()
		
		if resetState == 'defense' then
			state.Defense.Active = false
			add_to_chat(122,state.Defense.Type..' defense is now off.')
		elseif resetState == 'kite' or resetState == 'kiting' then
			state.Kiting = false
			add_to_chat(122,'Kiting is now off.')
		elseif resetState == 'melee' then
			state.OffenseMode = options.OffenseModes[1]
			state.DefenseMode = options.DefenseModes[1]
			add_to_chat(122,'Melee has been reset to defaults.')
		elseif resetState == 'casting' then
			state.CastingMode = options.CastingModes[1]
			add_to_chat(122,'Casting has been reset to default.')
		elseif resetState == 'distance' then
			state.MaxWeaponskillDistance = 0
			add_to_chat(122,'Max weaponskill distance limitations have been removed.')
		elseif resetState == 'target' then
			state.SelectNPCTargets = false
			state.PCTargetMode = 'default'
			add_to_chat(122,'Adjusting target selection has been turned off.')
		elseif resetState == 'all' then
			state.Defense.Active = false
			state.Defense.PhysicalMode = options.PhysicalDefenseModes[1]
			state.Defense.MagicalMode = options.MagicalDefenseModes[1]
			state.Kiting = false
			state.OffenseMode = options.OffenseModes[1]
			state.DefenseMode = options.DefenseModes[1]
			state.CastingMode = options.CastingModes[1]
			state.IdleMode = options.IdleModes[1]
			state.RestingMode = options.RestingModes[1]
			state.MaxWeaponskillDistance = 0
			state.SelectNPCTargets = false
			state.PCTargetMode = 'default'
			showSet = nil
			add_to_chat(122,'Everything has been reset to defaults.')
		else
			if _global.debug_mode then add_to_chat(123,'--handle_reset unknown state to reset: '..resetState) end
			return false
		end
		

		if job_state_change then
			job_state_change('Reset', resetState)
		end
	else
		if _global.debug_mode then add_to_chat(123,'--handle_activate parameter failure: field not specified') end
		return false
	end
	
	handle_update({'auto'})
	return true
end


-- User command format: gs c update [option]
-- Where [option] can be 'user' to display current state.
-- Otherwise, generally refreshes current gear used.
function MoteInclude.handle_update(cmdParams)
	-- init a new eventArgs
	local eventArgs = {handled = false}

	-- Allow jobs to override this code
	if job_update then
		job_update(cmdParams, eventArgs)
	end

	if not eventArgs.handled then
		handle_equipping_gear(player.status)
	end
	
	if cmdParams[1] == 'user' then
		display_current_state()
	end
end


-- showset: equip the current TP set for examination.
function MoteInclude.handle_show_set(cmdParams)
	-- If no extra parameters, or 'tp' as a parameter, show the current TP set.
	if #cmdParams == 0 or cmdParams[1]:lower() == 'tp' then
		local meleeGroups = ''
		if #classes.CustomMeleeGroups > 0 then
			meleeGroups = ' ['
			for i = 1,#classes.CustomMeleeGroups do
				meleeGroups = meleeGroups..classes.CustomMeleeGroups[i]
			end
			meleeGroups = meleeGroups..']'
		end
		
		add_to_chat(122,'Showing current TP set: ['..state.OffenseMode..'/'..state.DefenseMode..']'..meleeGroups)
		equip(get_current_melee_set())
	-- If given a param of 'precast', block equipping midcast/aftercast sets
	elseif cmdParams[1]:lower() == 'precast' then
		showSet = 'precast'
		add_to_chat(122,'GearSwap will now only equip up to precast gear for spells/actions.')
	-- If given a param of 'midcast', block equipping aftercast sets
	elseif cmdParams[1]:lower() == 'midcast' then
		showSet = 'midcast'
		add_to_chat(122,'GearSwap will now only equip up to midcast gear for spells.')
	-- With a parameter of 'off', turn off showset functionality.
	elseif cmdParams[1]:lower() == 'off' then
		showSet = nil
		add_to_chat(122,'Show Sets is turned off.')
	end
end

-- Minor variation on the GearSwap "gs equip naked" command, that ensures that
-- all slots are enabled before removing gear.
-- Command: "gs c naked"
function MoteInclude.handle_naked(cmdParams)
	enable('main','sub','range','ammo','head','neck','lear','rear','body','hands','lring','rring','back','waist','legs','feet')
	equip(sets.naked)
end


------  Utility functions to support self commands. ------

-- Function to get the options.XXXModes table and the corresponding state value to make given state field.
function MoteInclude.get_mode_table(field)
	local modeTable = {}
	local currentValue = ''

	if field == 'Offense' then
		modeTable = options.OffenseModes
		currentValue = state.OffenseMode
	elseif field == 'Defense' then
		modeTable = options.DefenseModes
		currentValue = state.DefenseMode
	elseif field == 'Casting' then
		modeTable = options.CastingModes
		currentValue = state.CastingMode
	elseif field == 'Weaponskill' then
		modeTable = options.WeaponskillModes
		currentValue = state.WeaponskillMode
	elseif field == 'Idle' then
		modeTable = options.IdleModes
		currentValue = state.IdleMode
	elseif field == 'Resting' then
		modeTable = options.RestingModes
		currentValue = state.RestingMode
	elseif field == 'Physicaldefense' then
		modeTable = options.PhysicalDefenseModes
		currentValue = state.Defense.PhysicalMode
	elseif field == 'Magicaldefense' then
		modeTable = options.MagicalDefenseModes
		currentValue = state.Defense.MagicalMode
	elseif field == 'Target' then
		modeTable = options.TargetModes
		currentValue = state.PCTargetMode
	elseif job_get_mode_table then
		-- Allow job scripts to expand the mode table lists
		modeTable, currentValue, err = job_get_mode_table(field)
		if err then
			if _global.debug_mode then add_to_chat(123,'Attempt to query unknown state field: '..field) end
			return nil
		end
	else
		if _global.debug_mode then add_to_chat(123,'Attempt to query unknown state field: '..field) end
		return nil
	end
	
	return modeTable, currentValue
end

-- Function to set the appropriate state value for the specified field.
function MoteInclude.set_mode(field, val)
	if field == 'Offense' then
		state.OffenseMode = val
	elseif field == 'Defense' then
		state.DefenseMode = val
	elseif field == 'Casting' then
		state.CastingMode = val
	elseif field == 'Weaponskill' then
		state.WeaponskillMode = val
	elseif field == 'Idle' then
		state.IdleMode = val
	elseif field == 'Resting' then
		state.RestingMode = val
	elseif field == 'Physicaldefense' then
		state.Defense.PhysicalMode = val
	elseif field == 'Magicaldefense' then
		state.Defense.MagicalMode = val
	elseif field == 'Target' then
		state.PCTargetMode = val
	elseif job_set_mode then
		-- Allow job scripts to expand the mode table lists
		if not job_set_mode(field, val) then
			if _global.debug_mode then add_to_chat(123,'Attempt to set unknown state field: '..field) end
		end
	else
		if _global.debug_mode then add_to_chat(123,'Attempt to set unknown state field: '..field) end
	end
end


-- Function to display the current relevant user state when doing an update.
-- Uses display_current_job_state instead if that is defined in the job lua.
function MoteInclude.display_current_state()
	local eventArgs = {handled = false}
	if display_current_job_state then
		display_current_job_state(eventArgs)
	end
	
	if not eventArgs.handled then
		local defenseString = ''
		if state.Defense.Active then
			local defMode = state.Defense.PhysicalMode
			if state.Defense.Type == 'Magical' then
				defMode = state.Defense.MagicalMode
			end
	
			defenseString = 'Defense: '..state.Defense.Type..' '..defMode..', '
		end
		
		local pcTarget = ''
		if state.PCTargetMode ~= 'default' then
			pcTarget = ', Target PC: '..state.PCTargetMode
		end

		local npcTarget = ''
		if state.SelectNPCTargets then
			pcTarget = ', Target NPCs'
		end
		

		add_to_chat(122,'Melee: '..state.OffenseMode..'/'..state.DefenseMode..', WS: '..state.WeaponskillMode..', '..defenseString..
			'Kiting: '..on_off_names[state.Kiting]..pcTarget..npcTarget)
	end
	
	if showSet then
		add_to_chat(122,'Show Sets it currently showing ['..showSet..'] sets.  Use "//gs c showset off" to turn it off.')
	end
end


-------------------------------------------------------------------------------------------------------------------
-- Utility functions for changing spells and targets.
-------------------------------------------------------------------------------------------------------------------

function MoteInclude.auto_change_target(spell, action, spellMap)
	-- Do not modify target for spells where we get <lastst> or <me>.
	if spell.target.raw == ('<lastst>') or spell.target.raw == ('<me>') then
		return
	end
	
	-- init a new eventArgs
	local eventArgs = {handled = false, pcTargetMode = 'default', selectNPCTargets = false}

	-- Allow the job to do custom handling
	-- They can completely handle it, or set one of the secondary eventArgs vars to selectively
	-- override the default state vars.
	if job_auto_change_target then
		job_auto_change_target(spell, action, spellMap, eventArgs)
	end
	
	-- If the job handled it, we're done.
	if eventArgs.handled then
		return
	end
			

	local canUseOnPlayer = spell.validtarget.Self or spell.validtarget.Player or spell.validtarget.Party or spell.validtarget.Ally or spell.validtarget.NPC

	local newTarget = ''
	
	-- For spells that we can cast on players:
	if canUseOnPlayer then
		if eventArgs.pcTargetMode == 'stal' or state.PCTargetMode == 'stal' then
			-- Use <stal> if possible, otherwise fall back to <stpt>.
			if spell.validtarget.Ally then
				newTarget = '<stal>'
			elseif spell.validtarget.Party then
				newTarget = '<stpt>'
			end
		elseif eventArgs.pcTargetMode == 'stpt' or state.PCTargetMode == 'stpt' then
			-- Even ally-possible spells are limited to the current party.
			if spell.validtarget.Ally or spell.validtarget.Party then
				newTarget = '<stpt>'
			end
		elseif eventArgs.pcTargetMode == 'stpc' or state.PCTargetMode == 'stpc' then
			-- If it's anything other than a self-only spell, can change to <stpc>.
			if spell.validtarget.Player or spell.validtarget.Party or spell.validtarget.Ally or spell.validtarget.NPC then
				newTarget = '<stpc>'
			end
		end
	-- For spells that can be used on enemies:
	elseif spell.validtarget.Enemy then
		if eventArgs.selectNPCTargets or state.SelectNPCTargets then
			-- Note: this means macros should be written for <t>, and it will change to <stnpc>
			-- if the flag is set.  It won't change <stnpc> back to <t>.
			newTarget = '<stnpc>'
		end
	end
	
	-- If a new target was selected and is different from the original, call the change function.
	if newTarget ~= '' and newTarget ~= spell.target.raw then
		change_target(newTarget)
	end
end

-------------------------------------------------------------------------------------------------------------------
-- Utility functions for common gear equips.
-------------------------------------------------------------------------------------------------------------------

-- Add the obi for the given element if it matches either the current weather or day.
function MoteInclude.add_obi(spell_element)
	if gear.Obi[spell_element] and (world.weather_element == spell_element or world.day_element == spell_element) then
		equip({waist=gear.Obi[spell_element]})
	end
end


-------------------------------------------------------------------------------------------------------------------
-- Utility functions for vars or other data manipulation.
-------------------------------------------------------------------------------------------------------------------

---Name: split()
---Args:
----- msg (string): message to be subdivided
----- delim (string/char): marker for subdivision
------------------------------------------------------------------------------------
---Returns:
----- Table containing string(s)
------------------------------------------------------------------------------------
function MoteInclude.split(msg, delim)
	local result = T{}

	-- If no delimiter specified, just extract alphabetic words
	if not delim or delim == '' then
		for word in msg:gmatch("%a+") do
			result[#result+1] = word
		end
	else
		-- If the delimiter isn't in the message, just return the whole message
		if string.find(msg, delim) == nil then
			result[1] = msg
		else
			-- Otherwise use a capture pattern based on the delimiter to
			-- extract text chunks.
			local pat = "(.-)" .. delim .. "()"
			local lastPos
			for part, pos in msg:gmatch(pat) do
				result[#result+1] = part
				lastPos = pos
			end
			-- Handle the last field
			if #msg > lastPos then
				result[#result+1] = msg:sub(lastPos)
			end
		end
	end
	
	return result
end


-- Invert a table such that the keys are values and the values are keys.
-- Use this to look up the index value of a given entry.
function MoteInclude.invert_table(t)
	if t == nil then add_to_chat(123,'Attempting to invert table, received nil.') end
	
	local i={}
	for k,v in pairs(t) do 
		i[v] = k
	end
	return i
end

-- Gets sub-tables based on baseSet from the string str that may be in dot form
-- (eg: baseSet=sets, str='precast.FC', this returns sets.precast.FC).
function MoteInclude.get_expanded_set(baseSet, str)
	local cur = baseSet
	for i in str:gmatch("[^.]+") do
		cur = cur[i]
	end
	
	return cur
end


-------------------------------------------------------------------------------------------------------------------
-- Handle generic binds on load/unload of GearSwap.
-------------------------------------------------------------------------------------------------------------------


-- Function to bind GearSwap binds when loading a GS script.
function MoteInclude.gearswap_binds_on_load()
	windower.send_command('bind f9 gs c cycle OffenseMode')
	windower.send_command('bind ^f9 gs c cycle DefenseMode')
	windower.send_command('bind !f9 gs c cycle WeaponskillMode')
	windower.send_command('bind f10 gs c activate PhysicalDefense')
	windower.send_command('bind ^f10 gs c cycle PhysicalDefenseMode')
	windower.send_command('bind !f10 gs c toggle kiting')
	windower.send_command('bind f11 gs c activate MagicalDefense')
	windower.send_command('bind ^f11 gs c cycle CastingMode')
	windower.send_command('bind !f11 gs c set CastingMode Dire')
	windower.send_command('bind f12 gs c update user')
	windower.send_command('bind ^f12 gs c cycle IdleMode')
	windower.send_command('bind !f12 gs c reset defense')
end

-- Function to re-bind Spellcast binds when unloading GearSwap.
function MoteInclude.spellcast_binds_on_unload()
	windower.send_command('bind f9 input /ma CombatMode Cycle(Offense)')
	windower.send_command('bind ^f9 input /ma CombatMode Cycle(Defense)')
	windower.send_command('bind !f9 input /ma CombatMode Cycle(WS)')
	windower.send_command('bind f10 input /ma PhysicalDefense .On')
	windower.send_command('bind ^f10 input /ma PhysicalDefense .Cycle')
	windower.send_command('bind !f10 input /ma CombatMode Toggle(Kite)')
	windower.send_command('bind f11 input /ma MagicalDefense .On')
	windower.send_command('bind ^f11 input /ma CycleCastingMode')
	windower.send_command('bind !f11 input /ma CastingMode Dire')
	windower.send_command('bind f12 input /ma Update .Manual')
	windower.send_command('bind ^f12 input /ma CycleIdleMode')
	windower.send_command('bind !f12 input /ma Reset .Defense')
end

-------------------------------------------------------------------------------------------------------------------
-- Handle generic binds on load/unload of GearSwap.
-------------------------------------------------------------------------------------------------------------------

-- Returns a table of spell mappings to allow grouping classes of spells that are otherwise disparately named.
function MoteInclude.get_spell_mappings()
	local mappings = {
		['Cure']='Cure',['Cure II']='Cure',['Cure III']='Cure',['Cure IV']='Cure',['Cure V']='Cure',['Cure VI']='Cure',
		['Cura']='Curaga',['Cura II']='Curaga',['Cura III']='Curaga',
		['Curaga']='Curaga',['Curaga II']='Curaga',['Curaga III']='Curaga',['Curaga IV']='Curaga',['Curaga V']='Curaga',
		['Barfire']='Barspell',['Barstone']='Barspell',['Barwater']='Barspell',['Baraero']='Barspell',['Barblizzard']='Barspell',['Barthunder']='Barspell',
		['Barfira']='Barspell',['Barstonra']='Barspell',['Barwatera']='Barspell',['Baraera']='Barspell',['Barblizzara']='Barspell',['Barthundra']='Barspell',
		['Foe Lullaby']='Lullaby',['Foe Lullaby II']='Lullaby',['Horde Lullaby']='Lullaby',['Horde Lullaby II']='Lullaby',
		["Mage's Ballad"]='Ballad',["Mage's Ballad II"]='Ballad',["Mage's Ballad III"]='Ballad',
		['Advancing March']='March',['Victory March']='March',
		['Sword Madrigal']='Madrigal',['Blade Madrigal']='Madrigal',
		['Valor Minuet']='Minuet',['Valor Minuet II']='Minuet',['Valor Minuet III']='Minuet',['Valor Minuet IV']='Minuet',['Valor Minuet V']='Minuet',
		["Knight's Minne"]='Minne',["Knight's Minne II"]='Minne',["Knight's Minne III"]='Minne',["Knight's Minne IV"]='Minne',["Knight's Minne V"]='Minne',
		["Army's Paeon"]='Paeon',["Army's Paeon II"]='Paeon',["Army's Paeon III"]='Paeon',["Army's Paeon IV"]='Paeon',["Army's Paeon V"]='Paeon',["Army's Paeon VI"]='Paeon',
		['Fire Carol']='Carol',['Ice Carol']='Carol',['Wind Carol']='Carol',['Earth Carol']='Carol',['Lightning Carol']='Carol',['Water Carol']='Carol',['Light Carol']='Carol',['Dark Carol']='Carol',
		['Fire Carol II']='Carol',['Ice Carol II']='Carol',['Wind Carol II']='Carol',['Earth Carol II']='Carol',['Lightning Carol II']='Carol',['Water Carol II']='Carol',['Light Carol II']='Carol',['Dark Carol II']='Carol',
		['Regen']='Regen',['Regen II']='Regen',['Regen III']='Regen',['Regen IV']='Regen',['Regen V']='Regen',
		['Refresh']='Refresh',['Refresh II']='Refresh',
		['Protect']='Protect',['Protect II']='Protect',['Protect III']='Protect',['Protect IV']='Protect',['Protect V']='Protect',
		['Shell']='Shell',['Shell II']='Shell',['Shell III']='Shell',['Shell IV']='Shell',['Shell V']='Shell',
		['Protectra']='Protectra',['Protectra II']='Protectra',['Protectra III']='Protectra',['Protectra IV']='Protectra',['Protectra V']='Protectra',
		['Shellra']='Shellra',['Shellra II']='Shellra',['Shellra III']='Shellra',['Shellra IV']='Shellra',['Shellra V']='Shellra',
		-- Status Removal doesn't include Esuna or Sacrifice, since they work differently than the rest
		['Poisona']='StatusRemoval',['Paralyna']='StatusRemoval',['Silena']='StatusRemoval',['Blindna']='StatusRemoval',['Cursna']='StatusRemoval',
		['Stona']='StatusRemoval',['Viruna']='StatusRemoval',['Erase']='StatusRemoval',
		['Utsusemi: Ichi']='Utsusemi',['Utsusemi: Ni']='Utsusemi',
		['Burn']='ElementalEnfeeble',['Frost']='ElementalEnfeeble',['Choke']='ElementalEnfeeble',['Rasp']='ElementalEnfeeble',['Shock']='ElementalEnfeeble',['Drown']='ElementalEnfeeble',
		['Pyrohelix']='Helix',['Cryohelix']='Helix',['Anemohelix']='Helix',['Geohelix']='Helix',['Ionohelix']='Helix',['Hydrohelix']='Helix',['Luminohelix']='Helix',['Noctohelix']='Helix',
		['Firestorm']='Storm',['Hailstorm']='Storm',['Windstorm']='Storm',['Sandstorm']='Storm',['Thunderstorm']='Storm',['Rainstorm']='Storm',['Aurorastorm']='Storm',['Voidstorm']='Storm',
		['Teleport-Holla']='Teleport',['Teleport-Dem']='Teleport',['Teleport-Mea']='Teleport',['Teleport-Altep']='Teleport',['Teleport-Yhoat']='Teleport',
		['Teleport-Vahzl']='Teleport',['Recall-Pashh']='Teleport',['Recall-Meriph']='Teleport',['Recall-Jugner']='Teleport',
		['Raise']='Raise',['Raise II']='Raise',['Raise III']='Raise',['Arise']='Raise',
		['Reraise']='Reraise',['Reraise II']='Reraise',['Reraise III']='Reraise',
		['Fire Maneuver']='Maneuver',['Ice Maneuver']='Maneuver',['Wind Maneuver']='Maneuver',['Earth Maneuver']='Maneuver',['Thunder Maneuver']='Maneuver',
		['Water Maneuver']='Maneuver',['Light Maneuver']='Maneuver',['Dark Maneuver']='Maneuver',
	}

	return mappings
end


-------------------------------------------------------------------------------------------------------------------
-- Test functions.
-------------------------------------------------------------------------------------------------------------------

-- A function for testing lua code.  Called via "gs c test".
function MoteInclude.handle_test(cmdParams)
end


-- Done with defining the module.  Return the table.
return MoteInclude
