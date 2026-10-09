--[[
    Knox Bite Immunity - core logic (Project Zomboid Build 42.20+)

    Idea
    ----
    The bite itself (damage, pain, bleeding, deep wound, bandage need, bacterial
    wound infection) is never touched. We only watch the Knox virus flag:
    when it flips from "not infected" to "infected" and the evidence says the
    cause was a bite, we revert ONLY the virus state.

    API used (all present in the 42.20.0 javadoc):
      BodyDamage : isInfected, setInfected, getInfectionTime, setInfectionTime,
                   getInfectionMortalityDuration, setInfectionMortalityDuration,
                   getBodyParts
      BodyPart   : bitten, scratched, isCut, IsInfected, SetInfected
    No method takes a BodyPartType enum (avoids the Kahlua enum-bridge problem).

    Attribution rule on a new Knox infection
    ----------------------------------------
      * some part is newly scratched / newly cut, or a newly infected part is
        scratched/cut but not bitten  -> NOT a bite -> left exactly as vanilla
      * otherwise                      -> bite        -> virus state reverted
]]

local Core = {}

Core.DEBUG = false

local function log(msg)
    if Core.DEBUG then
        print("[KnoxBiteImmunity] " .. tostring(msg))
    end
end

local function newState()
    return {
        ready     = false,
        infected  = false,
        scratched = {},
        cut       = {},
        partInf   = {},
        infTime   = -1,
        infMort   = -1,
    }
end

Core.newState = newState

-- Record the current wound/virus state. Only called while NOT infected, so the
-- infection timers stored here are the vanilla "clean" values.
local function snapshot(bd, st)
    local parts = bd:getBodyParts()
    for i = 0, parts:size() - 1 do
        local p = parts:get(i)
        st.scratched[i] = p:scratched()
        st.cut[i]       = p:isCut()
        st.partInf[i]   = p:IsInfected()
    end
    st.infected = false
    st.infTime  = bd:getInfectionTime()
    st.infMort  = bd:getInfectionMortalityDuration()
    st.ready    = true
end

-- Decide whether a fresh Knox infection came from a bite.
-- true  = bite (revert), false = scratch/laceration (keep as vanilla).
local function causedByBite(bd, st)
    local parts = bd:getBodyParts()
    for i = 0, parts:size() - 1 do
        local p = parts:get(i)
        local bitten    = p:bitten()
        local scratched = p:scratched()
        local cut       = p:isCut()

        -- a wound of a non-bite type appeared this tick
        if scratched and not st.scratched[i] and not bitten then return false end
        if cut and not st.cut[i] and not bitten then return false end

        -- the virus appeared on a part carrying a scratch/laceration only
        if p:IsInfected() and not st.partInf[i] and not bitten and (scratched or cut) then
            return false
        end
    end
    -- No evidence of a non-bite wound: the only remaining source of a brand
    -- new Knox infection is a bite (possibly on an already bitten part).
    return true
end

-- Revert ONLY the Knox virus state (not the wound).
local function neutralize(bd, st)
    local parts = bd:getBodyParts()
    for i = 0, parts:size() - 1 do
        local p = parts:get(i)
        if p:bitten() and p:IsInfected() and not st.partInf[i] then
            p:SetInfected(false)
        end
    end
    bd:setInfected(false)
    bd:setInfectionTime(st.infTime)
    bd:setInfectionMortalityDuration(st.infMort)
end

-- Call once per tick for one player's BodyDamage.
function Core.update(bd, st)
    local nowInfected = bd:isInfected()

    if not st.ready then
        -- First tick after load / spawn. An infection that already exists
        -- (made before the mod was installed) is deliberately left alone.
        if nowInfected then
            st.infected = true
            st.ready = true
        else
            snapshot(bd, st)
        end
        return
    end

    if nowInfected then
        if not st.infected then
            if causedByBite(bd, st) then
                neutralize(bd, st)
                log("bite infection reverted")
                snapshot(bd, st)
            else
                st.infected = true
                log("non-bite infection kept (vanilla behaviour)")
            end
        end
        return
    end

    snapshot(bd, st)
end

return Core
