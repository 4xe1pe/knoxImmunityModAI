-- Knox Bite Immunity - event wiring (Project Zomboid Build 42.20+)
-- Nothing is stored in the save: the logic is stateless between sessions, so it
-- works on new and existing saves and survives save / quit / reload.

local Core = require("KnoxBiteImmunity_Core")

local states = {}
local failed = false

local function stateFor(player)
    local id = player:getPlayerNum()
    local st = states[id]
    if not st then
        st = Core.newState()
        states[id] = st
    end
    return st
end

local function onPlayerUpdate(player)
    if failed or not player or player:isDead() then return end
    local ok, err = pcall(function()
        Core.update(player:getBodyDamage(), stateFor(player))
    end)
    if not ok then
        failed = true -- stop instead of spamming errors every frame
        print("[KnoxBiteImmunity] disabled after error: " .. tostring(err))
    end
end

-- New character (new game, respawn, load): rebuild the snapshot from scratch.
local function onCreatePlayer(playerIndex, player)
    states[playerIndex] = Core.newState()
end

Events.OnPlayerUpdate.Add(onPlayerUpdate)
Events.OnCreatePlayer.Add(onCreatePlayer)
