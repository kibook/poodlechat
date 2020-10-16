-- Last player to send you a private message
local ReplyTo = nil

RegisterNetEvent('poodlechat:localMessage')
RegisterNetEvent('poodlechat:action')
RegisterNetEvent('poodlechat:whisperEcho')
RegisterNetEvent('poodlechat:whisper')
RegisterNetEvent('poodlechat:whisperError')
RegisterNetEvent('poodlechat:setReplyTo')

function AddLocalMessage(name, color, message)
	TriggerEvent('chat:addMessage', {color = color, args = {'[Local] ' .. name, message}})
end

function IsInProximity(id, distance)
	local myId = PlayerId()
	local pid = GetPlayerFromServerId(id)

	if pid == myId then
		return true
	end

	local myPed = GetPlayerPed(myId)
	local ped = GetPlayerPed(pid)

	if ped == 0 then
		return false
	end

	local myCoords = GetEntityCoords(myPed)
	local coords = GetEntityCoords(ped)

	return GetDistanceBetweenCoords(myCoords, coords, true) < distance
end

AddEventHandler('poodlechat:localMessage', function(id, name, color, message)
	if IsInProximity(id, Config.LocalMessageDistance) then
		AddLocalMessage(name, color, message)
	end
end)

AddEventHandler('poodlechat:action', function(id, name, message)
	if IsInProximity(id, Config.ActionDistance) then
		TriggerEvent('chat:addMessage', {color = Config.ActionColor, args = {'^*' .. name .. ' ' .. message}})
	end
end)

AddEventHandler('poodlechat:whisperEcho', function(id, name, message)
	TriggerEvent('chat:addMessage', {color = Config.WhisperEchoColor, args = {'[Whisper@' .. name .. ']', message}})
end)

AddEventHandler('poodlechat:whisper', function(id, name, message)
	TriggerEvent('chat:addMessage', {color = Config.WhisperColor, args = {'[Whisper] ' .. name, message}})
end)

AddEventHandler('poodlechat:whisperError', function(id)
	TriggerEvent('chat:addMessage', {color = {255, 0, 0}, args = {'Error', 'No user with ID or name ' .. id}})
end)

function ReplyCommand(source, args, user)
	if ReplyTo then
		local message = table.concat(args, " ")
		TriggerServerEvent('poodlechat:reply', ReplyTo, message)
	else
		TriggerEvent('chat:addMessage', {color = {255, 0, 0}, args = {'Error', 'No-one to reply to'}})
	end
end

RegisterCommand('reply', ReplyCommand, false)
RegisterCommand('r', ReplyCommand, false)

AddEventHandler('poodlechat:setReplyTo', function(id)
	ReplyTo = tostring(id)
end)

CreateThread(function()
	-- Command documentation
	TriggerEvent('chat:addSuggestion', '/clear', 'Clear chat window', {})
	TriggerEvent('chat:addSuggestion', '/global', 'Send a message to all players', {
		{name = 'message', help = 'The message to send'}
	})
	TriggerEvent('chat:addSuggestion', '/g', 'Send a message to all players', {
		{name = 'message', help = 'The message to send'}
	})
	TriggerEvent('chat:addSuggestion', '/me', 'Perform an action', {
		{name = 'action', help = 'The action to perform'}
	})
	TriggerEvent('chat:addSuggestion', '/reply', 'Reply to the last whisper', {
		{name = 'message', help = 'The message to send'}
	})
	TriggerEvent('chat:addSuggestion', '/r', 'Reply to the last whisper', {
		{name = 'message', help = 'The message to send'}
	})

	if IsDiscordReportEnabled() then
		TriggerEvent('chat:addSuggestion', '/report', 'Report another player for abuse', {
			{name = 'player', help = 'ID or name of the player to report'},
			{name = 'reason', help = 'Reason you are reporting this player'}
		})
	end

	TriggerEvent('chat:addSuggestion', '/say', 'Send a message to nearby players', {
		{name = "message", help = "The message to send"}
	})
	TriggerEvent('chat:addSuggestion', '/whisper', 'Send a private message', {
		{name = "player", help = "ID or name of the player to message"},
		{name = "message", help = "The message to send"}
	})
	TriggerEvent('chat:addSuggestion', '/w', 'Send a private message', {
		{name = "player", help = "ID or name of the player to message"},
		{name = "message", help = "The message to send"}
	})

	-- Emoji suggestions
	AddEmojiSuggestions()
end)
