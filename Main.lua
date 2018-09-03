
local ADDON_NAME = "RecreateGroup"
local VERSION = "@project-version@"
local log = FH3095Debug.log
local RG = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME)
_G.RecreateGroup = RG

function RG:resetVars()
	self.vars = {
		lastLeader = nil,
		savedGroup = {},
		joinedGroup = false,
	}
end

function RG:OnInitialize()
	self:resetVars()

	self.events = LibStub("AceEvent-3.0")
	self.events:RegisterEvent("PARTY_INVITE_REQUEST", function(_, leader) RG:eventPartyInvite(leader) end)
	self.events:RegisterEvent("GROUP_ROSTER_UPDATE", function() RG:eventGroupRosterUpdate() end)

	self.console = LibStub("AceConsole-3.0")
	local consoleCommandFunc = function(msg, editbox)
		RG:consoleParseCommand(msg, editbox)
	end
	self.console:RegisterChatCommand("RecreateGroup", consoleCommandFunc, true)
	self.console:RegisterChatCommand("RG", consoleCommandFunc, true)
end

function RG:consoleParseCommand(msg, editbox)
	local cmd = self.console:GetArgs(msg, 1)
	log("RG: got cmd", cmd, msg)

	if cmd == nil then
		cmd = "help"
	else
		cmd = cmd:lower()
	end

	if cmd == "help" then
		print("Available commands:")
		print("    save: Saves current group")
		print("    restore: Restores saved group. You have to bind this on a macro to work!!!")
		print("    reset: Resets saved group")
	elseif cmd == "save" then
		self:doSaveGroup()
	elseif cmd == "restore" then
		self:doRestoreGroup()
	elseif cmd == "reset" then
		self:resetVars()
		print("Resetted")
	else
		print("Error: Invalid command: " .. cmd)
	end
end

function RG:eventPartyInvite(leader)
	log("RG: Got invite", leader, self.vars.lastLeader)
	if self.vars.lastLeader == leader and leader ~= nil then
		self.vars.joinedGroup = true
		AcceptGroup()
		print("Automatically accepted invite of last group leader " .. leader)
	end
end

function RG:eventGroupRosterUpdate()
	-- Hide popup after joining the party automatically
	if self.vars.joinedGroup == true then
		self.vars.joinedGroup = false
		StaticPopup_Hide("PARTY_INVITE")
	end

	local leader = self:searchGroupLeader()
	if leader ~= nil and self.vars.lastLeader ~= leader then
		log("RG: New group leader", leader)
		self.vars.lastLeader = leader
	end
end

function RG:searchGroupLeader()
	if not IsInGroup(LE_PARTY_CATEGORY_HOME) or IsInRaid(LE_PARTY_CATEGORY_HOME) then
		return nil
	end
	if UnitIsGroupLeader("player") then
		return GetUnitName("player", true)
	end
	for i=1,4 do
		local u = "party" .. i
		if UnitIsGroupLeader(u) then
			return GetUnitName(u, true)
		end
	end
	return nil
end

function RG:doSaveGroup()
	local group = {}
	for i=1,4 do
		local u = "party" .. i
		if UnitExists(u) then
			group[GetUnitName(u, true)] = true
		end
	end
	self.vars.savedGroup = group
	print("Saved group")
	log("RG saved group", self.vars.savedGroup)
end

function RG:doRestoreGroup()
	if (IsInGroup(LE_PARTY_CATEGORY_HOME) and not UnitIsGroupLeader("player")) or IsInRaid(LE_PARTY_CATEGORY_HOME) then
		print("Error: Not group leader or in raid")
		return
	end
	for k,_ in pairs(self.vars.savedGroup) do
		UninviteUnit(k)
	end
	LeaveParty()
	for k,_ in pairs(self.vars.savedGroup) do
		InviteUnit(k)
	end
end
