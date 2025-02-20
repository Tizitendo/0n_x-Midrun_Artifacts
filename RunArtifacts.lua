RunArtifacts = Proxy.new()

local RemoveArtifacts = {}
RunArtifacts.remove = function(Artifact)
    table.insert(RemoveArtifacts, Artifact)
    local RemoveArtifact = Item.find("OnyxMidrunArtifacts", Artifact[2])
    Player.get_client():item_remove(RemoveArtifact)
    log.warning(Artifact[2])
    ActiveArti[Artifact[1].."-"..Artifact[2]] = false
end

gm.pre_script_hook(gm.constants.stage_goto, function(self, other, result, args)
    for i = #RemoveArtifacts, 1, -1 do
        DisableArtifact(RemoveArtifacts[i])
        table.remove(RemoveArtifacts, i)
    end
end)

RunArtifacts.activate = function(ArtifactID)
    
end
