-- Distance at which local messages are shown
local LocalMessageDistance = 50

-- Distance at which action messages are shown
local ActionDistance = 50

-- Color for action messages
local ActionColor = {200, 0, 255}

-- Last player to send you a private message
local ReplyTo = nil

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

RegisterNetEvent('poodlechat:localMessage')
AddEventHandler('poodlechat:localMessage', function(id, name, color, message)
	if IsInProximity(id, LocalMessageDistance) then
		AddLocalMessage(name, color, message)
	end
end)

RegisterNetEvent('poodlechat:action')
AddEventHandler('poodlechat:action', function(id, name, message)
	if IsInProximity(id, ActionDistance) then
		TriggerEvent('chat:addMessage', {color = ActionColor, args = {'^6' .. name .. ' ' .. message}})
	end
end)

RegisterNetEvent('poodlechat:whisperEcho')
AddEventHandler('poodlechat:whisperEcho', function(id, name, message)
	TriggerEvent('chat:addMessage', {color = {204, 77, 106}, args = {'[Whisper@' .. name .. ']', message}})
end)

RegisterNetEvent('poodlechat:whisper')
AddEventHandler('poodlechat:whisper', function(id, name, message)
	TriggerEvent('chat:addMessage', {color = {254, 127, 156}, args = {'[Whisper] ' .. name, message}})
end)

RegisterNetEvent('poodlechat:whisperError')
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

RegisterCommand('reply', function(source, args, user)
	ReplyCommand(source, args, user)
end, false)

RegisterCommand('r', function(source, args, user)
	ReplyCommand(source, args, user)
end, false)

RegisterNetEvent('poodlechat:setReplyTo')
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
	for i = 1, #emoji do
		for k = 1, #emoji[i][1] do
			TriggerEvent('chat:addSuggestion', emoji[i][1][k])
		end
	end
end)
