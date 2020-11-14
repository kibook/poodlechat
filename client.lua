local isRDR = not TerraingridActivate and true or false

local chatInputActive = false
local chatInputActivating = false
local chatHidden = true
local chatLoaded = false

-- Default channel
local Channel = 'Local'

-- Whether to hide the chat
local HideChat = false

RegisterNetEvent('chatMessage')
RegisterNetEvent('chat:addTemplate')
RegisterNetEvent('chat:addMessage')
RegisterNetEvent('chat:addSuggestion')
RegisterNetEvent('chat:addSuggestions')
RegisterNetEvent('chat:removeSuggestion')
RegisterNetEvent('chat:clear')

-- internal events
RegisterNetEvent('__cfx_internal:serverPrint')

RegisterNetEvent('_chat:messageEntered')

--deprecated, use chat:addMessage
AddEventHandler('chatMessage', function(author, color, text)
	local args = { text }
	if author ~= "" then
		table.insert(args, 1, author)
	end
	SendNUIMessage({
		type = 'ON_MESSAGE',
		message = {
			color = color,
			multiline = true,
			args = args
		}
	})
end)

AddEventHandler('__cfx_internal:serverPrint', function(msg)
	print(msg)

	SendNUIMessage({
		type = 'ON_MESSAGE',
		message = {
			templateId = 'print',
			multiline = true,
			args = { msg }
		}
	})
end)

AddEventHandler('chat:addMessage', function(message)
	SendNUIMessage({
		type = 'ON_MESSAGE',
		message = message
	})
end)

AddEventHandler('chat:addSuggestion', function(name, help, params)
	SendNUIMessage({
		type = 'ON_SUGGESTION_ADD',
		suggestion = {
			name = name,
			help = help,
			params = params or nil
		}
	})
end)

AddEventHandler('chat:addSuggestions', function(suggestions)
	for _, suggestion in ipairs(suggestions) do
		SendNUIMessage({
			type = 'ON_SUGGESTION_ADD',
			suggestion = suggestion
		})
	end
end)

AddEventHandler('chat:removeSuggestion', function(name)
	SendNUIMessage({
		type = 'ON_SUGGESTION_REMOVE',
		name = name
	})
end)

AddEventHandler('chat:addTemplate', function(id, html)
	SendNUIMessage({
		type = 'ON_TEMPLATE_ADD',
		template = {
			id = id,
			html = html
		}
	})
end)

AddEventHandler('chat:clear', function(name)
	SendNUIMessage({
		type = 'ON_CLEAR'
	})
end)

RegisterNUICallback('chatResult', function(data, cb)
	chatInputActive = false
	SetNuiFocus(false)

	if not data.canceled then
		local id = PlayerId()

		--deprecated
		local r, g, b = 0, 0x99, 255

		if data.message:sub(1, 1) == '/' then
			ExecuteCommand(data.message:sub(2))
		else
			TriggerServerEvent('_chat:messageEntered', GetPlayerName(id), { r, g, b }, data.message, Channel)
		end
	end

	cb('ok')
end)

local function refreshCommands()
	if GetRegisteredCommands then
		local registeredCommands = GetRegisteredCommands()

		local suggestions = {}

		for _, command in ipairs(registeredCommands) do
			if IsAceAllowed(('command.%s'):format(command.name)) then
				table.insert(suggestions, {
					name = '/' .. command.name,
					help = ''
				})
			end
		end

		TriggerEvent('chat:addSuggestions', suggestions)
	end
end

local function refreshThemes()
	local themes = {}

	for resIdx = 0, GetNumResources() - 1 do
		local resource = GetResourceByFindIndex(resIdx)

		if GetResourceState(resource) == 'started' then
			local numThemes = GetNumResourceMetadata(resource, 'chat_theme')

			if numThemes > 0 then
				local themeName = GetResourceMetadata(resource, 'chat_theme')
				local themeData = json.decode(GetResourceMetadata(resource, 'chat_theme_extra') or 'null')

				if themeName and themeData then
					themeData.baseUrl = 'nui://' .. resource .. '/'
					themes[themeName] = themeData
				end
			end
		end
	end

	SendNUIMessage({
		type = 'ON_UPDATE_THEMES',
		themes = themes
	})
end

AddEventHandler('onClientResourceStart', function(resName)
	Wait(500)

	refreshCommands()
	refreshThemes()
end)

AddEventHandler('onClientResourceStop', function(resName)
	Wait(500)

	refreshCommands()
	refreshThemes()
end)

RegisterNUICallback('loaded', function(data, cb)
	TriggerServerEvent('chat:init');

	refreshCommands()
	refreshThemes()

	chatLoaded = true

	cb('ok')
end)

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

function SetChannel(name)
	Channel = name

	SendNUIMessage({
		type = 'setChannel',
		channelId = name == 'Local' and 'channel-local' or 'channel-global'
	})
end

RegisterNUICallback('setChannel', function(data, cb)
	local name
	if data.channelId == 'channel-local' then
		name = 'Local'
	elseif data.channelId == 'channel-global' then
		name = 'Global'
	end
	SetChannel(name)
	cb({})
end)

function CycleChannel()
	Channel = Channel == 'Local' and 'Global' or 'Local'
	SetChannel(Channel)
end

RegisterNUICallback('onLoad', function(data, cb)
	SetChannel(Channel)
	cb({
		localColor = Config.DefaultLocalColor,
		globalColor = Config.DefaultGlobalColor
	})
end)

RegisterNUICallback('cycleChannel', function(data, cb)
	CycleChannel()
	cb({})
end)

RegisterCommand('togglechat', function(source, args, raw)
	HideChat = not HideChat
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
	TriggerEvent('chat:addSuggestion', '/togglechat', 'Toggle the chat on/off', {})
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

	SetTextChatEnabled(false)
	SetNuiFocus(false)

	while true do
		Wait(0)

		if not chatInputActive then
			if IsControlPressed(0, isRDR and `INPUT_MP_TEXT_CHAT_ALL` or 245) --[[ INPUT_MP_TEXT_CHAT_ALL ]] then
				chatInputActive = true
				chatInputActivating = true

				SendNUIMessage({
					type = 'ON_OPEN'
				})
			end
		end

		if chatInputActivating then
			if not IsControlPressed(0, isRDR and `INPUT_MP_TEXT_CHAT_ALL` or 245) then
				SetNuiFocus(true, true)

				chatInputActivating = false
			end
		end

		if chatLoaded then
			local shouldBeHidden = false

			if IsScreenFadedOut() or IsPauseMenuActive() or HideChat then
				shouldBeHidden = true
			end

			if (shouldBeHidden and not chatHidden) or (not shouldBeHidden and chatHidden) then
				chatHidden = shouldBeHidden

				SendNUIMessage({
					type = 'ON_SCREEN_STATE_CHANGE',
					shouldHide = shouldBeHidden
				})
			end
		end
	end
end)
