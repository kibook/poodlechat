local isRDR = not TerraingridActivate and true or false

local chatInputActive = false
local chatInputActivating = false
local chatHidden = true
local chatLoaded = false

-- Default channel
local Channel = 'Local'

-- Whether to hide the chat
local HideChat = false

-- Players who's messages will be blocked
local MutedPlayers = {}

-- Frequencies of emoji usage
local EmojiUsage = {}

-- Display messages above players' heads
local DisplayMessagesAbovePlayers = ClientConfig.DisplayMessagesAbovePlayersByDefault

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

			exports.logmanager:log {
				message = ("Executed command: %s"):format(data.message:sub(2))
			}
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

local Permissions = {
	-- Whether this player has access to the Staff channel
	canAccessStaffChannel = false
}

RegisterNetEvent('poodlechat:globalMessage')
RegisterNetEvent('poodlechat:localMessage')
RegisterNetEvent('poodlechat:action')
RegisterNetEvent('poodlechat:whisperEcho')
RegisterNetEvent('poodlechat:whisper')
RegisterNetEvent('poodlechat:whisperError')
RegisterNetEvent('poodlechat:setReplyTo')
RegisterNetEvent('poodlechat:staffMessage')
RegisterNetEvent('poodlechat:setPermissions')
RegisterNetEvent('poodlechat:mute')
RegisterNetEvent('poodlechat:unmute')
RegisterNetEvent('poodlechat:showMuted')

local function getPedScreenCoord(ped)
	local pedCoords = GetEntityCoords(ped)
	local myCoords = GetEntityCoords(PlayerPedId())

	if #(myCoords - pedCoords) <= ClientConfig.OverheadMessageDistance then
		local min, max = GetModelDimensions(GetEntityModel(ped))
		local zOffset = (max.z - min.z) / 2
		return GetScreenCoordFromWorldCoord(pedCoords.x, pedCoords.y, pedCoords.z + zOffset)
	else
		return false, 0.0, 0.0
	end
end

local function displayTextAbovePlayer(serverId, color, text)
	local player = GetPlayerFromServerId(serverId)

	if player == -1 then
		return
	end

	local playerPed = GetPlayerPed(player)

	if not DoesEntityExist(playerPed) then
		return
	end

	local timeout = math.min(math.max(ClientConfig.MinOverheadMessageDisplayTime, text:len() * ClientConfig.OverheadMessageDisplayTimePerChar), ClientConfig.MaxOverheadMessageDisplayTime)

	SendNUIMessage {
		type = "create3dMessage",
		id = serverId,
		color = color,
		text = text,
		timeout = timeout
	}

	Citizen.CreateThread(function()
		local endTime = GetGameTimer() + timeout

		while GetGameTimer() < endTime do
			local onScreen, screenX, screenY = getPedScreenCoord(playerPed)

			SendNUIMessage {
				type = 'update3dMessage',
				id = serverId,
				onScreen = onScreen,
				screenX = screenX,
				screenY = screenY
			}

			Citizen.Wait(50)
		end
	end)
end

function GlobalCommand(source, args, user)
	TriggerServerEvent('poodlechat:globalMessage', table.concat(args, ' '))
end

RegisterCommand('global', GlobalCommand, false)
RegisterCommand('g', GlobalCommand, false)

RegisterCommand('me', function(source, args, raw)
	TriggerServerEvent('poodlechat:actionMessage', table.concat(args, ' '))
end, false)

function WhisperCommand(source, args, user)
	local id = args[1]

	table.remove(args, 1)
	local message = table.concat(args, ' ')

	TriggerServerEvent('poodlechat:whisperMessage', id, message)
end

RegisterCommand('whisper', WhisperCommand, false)
RegisterCommand('w', WhisperCommand, false)

RegisterCommand('clear', function(source, args, user)
	TriggerEvent('chat:clear', source)
end, false)

RegisterCommand('toggleoverhead', function(source, args, raw)
	DisplayMessagesAbovePlayers = not DisplayMessagesAbovePlayers

	TriggerEvent('chat:addMessage', {
		color = {255, 255, 128},
		args = {'Overhead messages', DisplayMessagesAbovePlayers and 'on' or 'off'}
	})

	SetResourceKvp("displayMessagesAbovePlayers", DisplayMessagesAbovePlayers and "true" or "false")
end, false)

function AddGlobalMessage(name, color, message)
	TriggerEvent('chat:addMessage', {color = color, args = {'[Global] ' .. name, message}})
end

AddEventHandler('poodlechat:globalMessage', function(id, license, name, color, message)
	if MutedPlayers[license] then
		return
	end

	AddGlobalMessage(name, color, message)

	if DisplayMessagesAbovePlayers then
		displayTextAbovePlayer(id, color, message)
	end
end)

function AddLocalMessage(name, color, message)
	TriggerEvent('chat:addMessage', {color = color, args = {'[Local] ' .. name, message}})
end

function IsInProximity(id, distance)
	local myId = PlayerId()
	local pid = GetPlayerFromServerId(id)

	if pid == -1 then
		return false
	end

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

	return #(myCoords - coords) < distance
end

AddEventHandler('poodlechat:localMessage', function(id, license, name, color, message)
	if MutedPlayers[license] then
		return
	end

	if IsInProximity(id, Config.LocalMessageDistance) then
		AddLocalMessage(name, color, message)

		if DisplayMessagesAbovePlayers then
			displayTextAbovePlayer(id, color, message)
		end
	end
end)

AddEventHandler('poodlechat:action', function(id, license, name, message)
	if MutedPlayers[license] then
		return
	end

	if IsInProximity(id, Config.ActionDistance) then
		TriggerEvent('chat:addMessage', {color = Config.ActionColor, args = {'^*' .. name .. '^r^* ' .. message}})

		if DisplayMessagesAbovePlayers then
			displayTextAbovePlayer(id, Config.ActionColor, '*' .. message .. '*')
		end
	end
end)

AddEventHandler('poodlechat:whisperEcho', function(id, license, name, message)
	if MutedPlayers[license] then
		TriggerEvent('chat:addMessage', {
			color = {255, 0, 0},
			args = {'Error', name .. ' is muted'}
		})
		return
	end

	TriggerEvent('chat:addMessage', {color = Config.WhisperEchoColor, args = {'[Whisper@' .. name .. ']', message}})

	if DisplayMessagesAbovePlayers then
		displayTextAbovePlayer(GetPlayerServerId(PlayerId()), Config.WhisperColor, message)
	end
end)

AddEventHandler('poodlechat:whisper', function(id, license, name, message)
	if MutedPlayers[license] then
		return
	end

	TriggerEvent('chat:addMessage', {color = Config.WhisperColor, args = {'[Whisper] ' .. name, message}})

	if DisplayMessagesAbovePlayers then
		displayTextAbovePlayer(id, Config.WhisperColor, message)
	end
end)

AddEventHandler('poodlechat:whisperError', function(id)
	TriggerEvent('chat:addMessage', {color = {255, 0, 0}, args = {'Error', 'No user with ID or name ' .. id}})
end)

function ReplyCommand(source, args, user)
	if ReplyTo then
		local message = table.concat(args, " ")
		TriggerServerEvent('poodlechat:whisperMessage', ReplyTo, message)
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

	local channelId

	if name == 'Local' then
		channelId = 'channel-local'
	elseif name == 'Global' then
		channelId = 'channel-global'
	elseif name == 'Staff' then
		channelId = 'channel-staff'
	end

	SendNUIMessage({
		type = 'setChannel',
		channelId = channelId
	})
end

RegisterNUICallback('setChannel', function(data, cb)
	local name
	if data.channelId == 'channel-local' then
		name = 'Local'
	elseif data.channelId == 'channel-global' then
		name = 'Global'
	elseif data.channelId == 'channel-staff' then
		name = 'Staff'
	end
	SetChannel(name)
	cb({})
end)

function CycleChannel()
	if Permissions.canAccessStaffChannel then
		if Channel == 'Local' then
			Channel = 'Global'
		elseif Channel == 'Global' then
			Channel = 'Staff'
		else
			Channel = 'Local'
		end
	else
		if Channel == 'Local' then
			Channel = 'Global'
		else
			Channel = 'Local'
		end
	end

	SetChannel(Channel)
end

function SortEmoji()
	local sortedEmoji = {}

	for i = 1, #Emoji do
		sortedEmoji[i] = Emoji[i]
	end

	table.sort(sortedEmoji, function(a, b)
		aUsage = EmojiUsage[a[2]] or 0
		bUsage = EmojiUsage[b[2]] or 0

		return aUsage > bUsage
	end)

	return sortedEmoji
end

RegisterNUICallback('onLoad', function(data, cb)
	SetChannel(Channel)
	cb({
		localColor = Config.DefaultLocalColor,
		globalColor = Config.DefaultGlobalColor,
		staffColor = Config.DefaultStaffColor,
		emoji = SortEmoji()
	})
end)

RegisterNUICallback('cycleChannel', function(data, cb)
	CycleChannel()
	cb({})
end)

RegisterNUICallback('useEmoji', function(data, cb)
	local usage = EmojiUsage[data.emoji] or 0
	EmojiUsage[data.emoji] = usage + 1
	cb(SortEmoji())
	SetResourceKvp('emojiUsage', json.encode(EmojiUsage))
end)

RegisterCommand('togglechat', function(source, args, raw)
	HideChat = not HideChat
end)

RegisterCommand('staff', function(source, args, raw)
	local message = table.concat(args, ' ')

	if message == '' then
		return
	end

	TriggerServerEvent('poodlechat:staffMessage', message)
end)

AddEventHandler('poodlechat:staffMessage', function(id, name, color, message)
	TriggerEvent('chat:addMessage', {
		color = color,
		args = {'[Staff] ' .. name, message}
	})

	if DisplayMessagesAbovePlayers then
		displayTextAbovePlayer(id, color, message)
	end
end)

AddEventHandler('poodlechat:setPermissions', function(permissions)
	Permissions = permissions

	SendNUIMessage({
		type = 'setPermissions',
		permissions = json.encode(permissions)
	})
end)

RegisterCommand('report', function(source, args, raw)
	if #args < 2 then
		TriggerEvent('chat:addMessage', {
			color = {255, 0, 0},
			args = {'Error', 'You must specify a player and a reason'}
		})
		return
	end

	local player = table.remove(args, 1)
	local reason = table.concat(args, ' ')

	TriggerServerEvent('poodlechat:report', player, reason)
end, false)

RegisterCommand('mute', function(source, args, raw)
	if #args < 1 then
		TriggerEvent('chat:addMessage', {
			color = {255, 0, 0},
			args = {'Error', 'You must specify a player to mute'}
		})
		return
	end

	local player = args[1]

	TriggerServerEvent('poodlechat:mute', player)
end, false)

AddEventHandler('poodlechat:mute', function(id, license)
	local name = GetPlayerName(GetPlayerFromServerId(id))

	MutedPlayers[license] = name

	TriggerEvent('chat:addMessage', {
		color = {255, 255, 128},
		args = {name .. ' was muted'}
	})

	SetResourceKvp('mutedPlayers', json.encode(MutedPlayers))
end)

RegisterCommand('unmute', function(source, args, raw)
	if #args < 1 then
		TriggerEvent('chat:addMessage', {
			color = {255, 0, 0},
			args = {'Error', 'You must specify a player to unmute'}
		})
		return
	end

	local player = args[1]

	TriggerServerEvent('poodlechat:unmute', player)
end)

AddEventHandler('poodlechat:unmute', function(id, license)
	local name = GetPlayerName(GetPlayerFromServerId(id))

	MutedPlayers[license] = nil

	TriggerEvent('chat:addMessage', {
		color = {255, 255, 128},
		args = {name .. ' was unmuted'}
	})

	SetResourceKvp('mutedPlayers', json.encode(MutedPlayers))
end)

RegisterCommand('muted', function(source, args, raw)
	TriggerServerEvent('poodlechat:showMuted', MutedPlayers)
end)

AddEventHandler('poodlechat:showMuted', function(mutedPlayerIds)
	local muted = {}

	table.sort(mutedPlayerIds)

	for _, id in ipairs(mutedPlayerIds) do
		local name = GetPlayerName(GetPlayerFromServerId(id))
		table.insert(muted, string.format('%s [%d]', name, id))
	end

	if #muted == 0 then
		TriggerEvent('chat:addMessage', {
			color = {255, 255, 128},
			args = {'No players are muted'}
		})
	else
		TriggerEvent('chat:addMessage', {
			color = {255, 255, 128},
			args = {'Muted', table.concat(muted, ', ')}
		})
	end
end)

function LoadSavedSettings()
	local mutedJson = GetResourceKvpString('mutedPlayers')

	if mutedJson then
		MutedPlayers = json.decode(mutedJson)
	end

	local emojiUsageJson = GetResourceKvpString('emojiUsage')

	if emojiUsageJson then
		EmojiUsage = json.decode(emojiUsageJson)
	end

	local displayMessagesAbovePlayers = GetResourceKvpString('displayMessagesAbovePlayers')

	if displayMessagesAbovePlayers then
		DisplayMessagesAbovePlayers = displayMessagesAbovePlayers == 'true'
	end
end

function AddEmojiSuggestions()
	for i = 1, #Emoji do
		for k = 1, #Emoji[i][1] do
			TriggerEvent('chat:addSuggestion', Emoji[i][1][k], Emoji[i][2])
		end
	end
end

CreateThread(function()
	TriggerServerEvent('poodlechat:getPermissions')

	LoadSavedSettings()

	-- Command documentation
	TriggerEvent('chat:addSuggestion', '/clear', 'Clear chat window')

	TriggerEvent('chat:addSuggestion', '/global', 'Send a message to all players', {
		{name = 'message', help = 'The message to send'}
	})
	TriggerEvent('chat:addSuggestion', '/g', 'Send a message to all players', {
		{name = 'message', help = 'The message to send'}
	})

	TriggerEvent('chat:addSuggestion', '/me', 'Perform an action', {
		{name = 'action', help = 'The action to perform'}
	})

	TriggerEvent('chat:addSuggestion', '/mute', 'Mute a player, hiding their messages in text chat', {
		{name = 'player', help = 'ID or name of the player to mute'}
	})

	TriggerEvent('chat:addSuggestion', '/muted', 'Show a list of muted players')

	TriggerEvent('chat:addSuggestion', '/nick', 'Set a nickname used for chat messages', {
		{name = 'nickname', help = 'The new nickname to use. Omit to unset your current nickname.'}
	})

	TriggerEvent('chat:addSuggestion', '/reply', 'Reply to the last whisper', {
		{name = 'message', help = 'The message to send'}
	})
	TriggerEvent('chat:addSuggestion', '/r', 'Reply to the last whisper', {
		{name = 'message', help = 'The message to send'}
	})

	TriggerEvent('chat:addSuggestion', '/report', 'Report another player for abuse', {
		{name = 'player', help = 'ID or name of the player to report'},
		{name = 'reason', help = 'Reason you are reporting this player'}
	})

	TriggerEvent('chat:addSuggestion', '/say', 'Send a message to nearby players', {
		{name = "message", help = "The message to send"}
	})

	TriggerEvent('chat:addSuggestion', '/togglechat', 'Toggle the chat on/off')

	TriggerEvent('chat:addSuggestion', '/unmute', 'Unmute a player, allowing you to see their messages in text chat again', {
		{name = 'player', help = 'ID or name of the player to unmute'}
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
		elseif IsControlJustReleased(0, isRDR and `INPUT_MP_TEXT_CHAT_ALL` or 245) then
			SetNuiFocus(true, true)
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
