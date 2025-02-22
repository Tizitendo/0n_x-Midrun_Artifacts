log.info("Successfully loaded " .. _ENV["!guid"] .. ".")
local envy = mods["MGReturns-ENVY"]
envy.auto()
mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto(true)

require("./RunArtifacts")

-- ========== ENVY Setup ==========

function public.setup(env)
    if env == nil then
        env = envy.getfenv(2)
    end
    local wrapper = {}
    for k, v in pairs(RunArtifacts) do
        wrapper[k] = v
    end
    return wrapper
end

mods.on_all_mods_loaded(function()
    for k, v in pairs(mods) do
        if type(v) == "table" and v.tomlfuncs then
            Toml = v
        end
    end
    params = {
        InventoryArtifacts = true
    }
    params = Toml.config_update(_ENV["!guid"], params) -- Load Save
end)

ActiveArti = {}
Initialize(function()
    local spiritStatHandler = Item.new("OnyxMidrunArtifacts", "spiritStatHandler", true)
    local ArtifactPacket = Packet.new()
    spiritStatHandler.is_hidden = true
    spiritStatHandler:toggle_loot(false)

    for _, Artifact in ipairs(Global.class_artifact) do
        if Artifact ~= 0 and Artifact[2] ~= 0 then
            local ArtifactItem = Item.new("OnyxMidrunArtifacts", Artifact[2], true)
            ArtifactItem:toggle_loot(false)
            ArtifactItem.token_name = Language.translate_token(Artifact[3])
            ArtifactItem.token_text = Language.translate_token(Artifact[5])
            ActiveArti[Artifact[1] .. "-" .. Artifact[2]] = false
        end
    end

    local function SetArtifactActive(Artifact)
        if Artifact[2] == "spirit" and not gm.bool(Artifact[9]) then
            local allies = Instance.find_all(gm.constants.pFriend)
            for i, ally in ipairs(allies) do
                ally:item_remove(spiritStatHandler)
                ally:item_give(spiritStatHandler)
            end
        end
        if Artifact[2] == "glass" and not gm.bool(Artifact[9]) then
            local allies = Instance.find_all(gm.constants.pFriend)
            for i, ally in ipairs(allies) do
                if ally.player_p_number ~= nil and ally.player_p_number > 0 then
                    ally:item_remove(Item.find("ror", "glassStatHandler"))
                    ally:item_give(Item.find("ror", "glassStatHandler"))
                end
            end
        end
        if Artifact[2] == "enigma" and not gm.bool(Artifact[9]) then
            local allies = Instance.find_all(gm.constants.pFriend)
            for i, ally in ipairs(allies) do
                if ally.player_p_number ~= nil and ally.player_p_number > 0 then
                    GM.equipment_set(ally, Equipment.find("ror", "artifactOfEnigma"))
                end
            end
        end
        if Artifact[2] ~= "kin" then
            Artifact[9] = true
        end

        if params.InventoryArtifacts then
            local GiveArtifact = Item.find("OnyxMidrunArtifacts", Artifact[2])
            GiveArtifact:set_sprite(Artifact[6])
            if Player.get_client():item_stack_count(Item.find("OnyxMidrunArtifacts", Artifact[2])) == 0 then
                Player.get_client():item_give(GiveArtifact)
            end
        end
    end

    function DisableArtifact(Artifact)
        if Artifact[2] == "spirit" and gm.bool(Artifact[9]) then
            local allies = Instance.find_all(gm.constants.pFriend)
            for i, ally in ipairs(allies) do
                ally:item_remove(spiritStatHandler)
            end
        end
        if Artifact[2] == "glass" and gm.bool(Artifact[9]) then
            local allies = Instance.find_all(gm.constants.pFriend)
            for i, ally in ipairs(allies) do
                if ally.player_p_number ~= nil and ally.player_p_number > 0 then
                    ally:item_remove(Item.find("ror", "glassStatHandler"))
                    ally:item_give(Item.find("ror", "glassStatHandler"))
                end
            end
        end
        if Artifact[2] == "enigma" and gm.bool(Artifact[9]) then
            local allies = Instance.find_all(gm.constants.pFriend)
            for i, ally in ipairs(allies) do
                if ally.player_p_number ~= nil and ally.player_p_number > 0 then
                    GM.equipment_set(ally, Equipment.find("ror", "artifactOfEnigma"))
                end
            end
        end
        Artifact[9] = false
    end

    local function NetworkArtifact(Artifact)
        if gm._mod_net_isOnline() then
            local msg = ArtifactPacket:message_begin()
            msg:write_instance(Artifact)
            if gm._mod_net_isClient() then
                msg:send_to_host()
            end
            if gm._mod_net_isHost() then
                msg:send_to_all()
            end
        end
        SetArtifactActive(Artifact)
    end

    ArtifactPacket:onReceived(function(msg)
        local Artifact = msg:read_instance()
        if gm._mod_net_isHost() then
            local msg = ArtifactPacket:message_begin()
            msg:write_instance(Artifact)
            msg:send_to_all()
        end
        SetArtifactActive(Artifact)
    end)

    gm.post_script_hook(gm.constants.add_item_pickup_display_for_player_gml_Object_oHUD_Create_0,
        function(self, other, result, args)
            if other ~= nil and other.artifact_id ~= nil then
                local Artifact = Global.class_artifact[other.artifact_id + 1]
                ActiveArti[Artifact[1].."-"..Artifact[2]] = true
                NetworkArtifact(Artifact)
            end
        end)

    gm.post_script_hook(gm.constants.enemy_stats_init, function(self, other, result, args)
        if ActiveArti["ror-spirit"] then
            Instance.wrap(self):item_give(spiritStatHandler)
        end
    end)

    gm.post_script_hook(gm.constants.drone_stats_init, function(self, other, result, args)
        if ActiveArti["ror-spirit"] then
            Instance.wrap(self):item_give(spiritStatHandler)
        end
    end)

    spiritStatHandler:onPostStep(function(actor, stack)
        actor.pHmax = actor.pHmax_raw - 2 * (actor.hp / actor.maxhp) + 2
    end)

    gm.pre_script_hook(gm.constants.stage_goto, function(self, other, result, args)
        if ActiveArti["ror-kin"] then
            for _, Artifact in ipairs(Global.class_artifact) do
                if Artifact ~= 0 and Artifact[2] == "kin" then
                    Artifact[9] = true
                end
            end
        end
    end)

    Callback.add(Callback.TYPE.onGameEnd, "OnyxMidrunArtifacts-onGameEnd", function()
        for _, Artifact in ipairs(Global.class_artifact) do
            if Artifact ~= 0 and Artifact[2] ~= 0 then
                ActiveArti[Artifact[1] .. "-" .. Artifact[2]] = false
            end
        end
    end)

    Callback.add(Callback.TYPE.onStep, "OnyxMidrunArtifacts-onStep", function()
        for _, Arti in ipairs(Global.class_artifact) do
            if Arti ~= 0 and ActiveArti[Arti[1] .. "-" .. Arti[2]] and
                Player.get_client():item_stack_count(Item.find("OnyxMidrunArtifacts", Arti[2])) == 0 then
                NetworkArtifact(Arti)
            end
        end
    end)

    -- Add ImGui window
    gui.add_to_menu_bar(function()
        params.InventoryArtifacts = ImGui.Checkbox("Arifacts appear in inventory", params.InventoryArtifacts)
        for _, Arti in ipairs(Global.class_artifact) do
            if Arti ~= 0 and Arti[2] ~= 0 then
                ActiveArti[Arti[1] .. "-" .. Arti[2]] = ImGui.Checkbox("Activate Artifact " .. Arti[2],
                    ActiveArti[Arti[1] .. "-" .. Arti[2]])
            end
        end
        Toml.save_cfg(_ENV["!guid"], params)
    end)
    gui.add_imgui(function()
        if ImGui.Begin("Midrun Artifacts") then
            params.InventoryArtifacts = ImGui.Checkbox("Arifacts appear in inventory", params.InventoryArtifacts)
            for _, Arti in ipairs(Global.class_artifact) do
                if Arti ~= 0 and Arti[2] ~= 0 then
                    ActiveArti[Arti[1] .. "-" .. Arti[2]] = ImGui.Checkbox("Activate Artifact " .. Arti[2],
                        ActiveArti[Arti[1] .. "-" .. Arti[2]])
                end
            end
            Toml.save_cfg(_ENV["!guid"], params)
        end
        ImGui.End()
    end)
end, true)
