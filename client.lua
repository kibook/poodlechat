-- Last player to send you a private message
local ReplyTo = nil

RegisterNetEvent('poodlechat:localMessage')
AddEventHandler('poodlechat:localMessage', function(id, name, message)
	local myId = PlayerId()
	local pid = GetPlayerFromServerId(id)
	if pid == myId then
		TriggerEvent('chat:addMessage', {color = {0, 153, 204}, args = {'[Local] ' .. name, message}})
	elseif GetDistanceBetweenCoords(GetEntityCoords(GetPlayerPed(myId)), GetEntityCoords(GetPlayerPed(pid)), true) < 19.999 then
		TriggerEvent('chat:addMessage', {color = {0, 153, 204}, args = {'[Local] ' .. name, message}})
	end
end)

RegisterNetEvent('poodlechat:action')
AddEventHandler('poodlechat:action', function(id, name, message)
	local myId = PlayerId()
	local pid = GetPlayerFromServerId(id)
	if pid == myId then
		TriggerEvent('chat:addMessage', {color = {200, 0, 255}, args = {'^6' .. name .. ' ' .. message}})
	elseif GetDistanceBetweenCoords(GetEntityCoords(GetPlayerPed(myId)), GetEntityCoords(GetPlayerPed(pid)), true) < 19.999 then
		TriggerEvent('chat:addMessage', {color = {200, 0, 255}, args = {'^6' .. name .. ' ' .. message}})
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
