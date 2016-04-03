function AnimateBuilders() {
    $.DispatchEvent("DOTAGlobalSceneFireEntityInput", "LightBuilder", "donkey", "SetAnimation", "spawn");
    $.DispatchEvent("DOTAGlobalSceneFireEntityInput", "DarkBuilder", "rex", "SetAnimation", "courier_spawn");
    $.DispatchEvent("DOTAGlobalSceneFireEntityInput", "WaterBuilder", "puppey", "SetAnimation", "spawn");
    $.DispatchEvent("DOTAGlobalSceneFireEntityInput", "FireBuilder", "hellsworn", "SetAnimation", "golem_spawn");
    //$.DispatchEvent("DOTAGlobalSceneFireEntityInput", "NatureBuilder", "otter", "SetAnimation", "spawn");
    $.DispatchEvent("DOTAGlobalSceneFireEntityInput", "EarthBuilder", "armadillo", "SetAnimation", "spawn");
}

function Hovering(name) {
    var panel = $("#"+name)
    panel.AddClass("Hovering")
    panel.hovering = true
}

function HoverOut(name) {
    var panel = $("#"+name)

    var hero =  Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer())
    var heroName = Entities.GetUnitName(hero)

    if (name != backgrounds[heroName])
        panel.RemoveClass("Hovering")
}

function ChooseBuilder(heroName) {
    GameEvents.SendCustomGameEventToServer( "player_choose_custom_builder", { "hero_name": heroName } );
    CloseCustomBuilders()
}

var backgrounds = {}
backgrounds["npc_dota_hero_skywrath_mage"] = "LightBackground"
backgrounds["npc_dota_hero_faceless_void"] = "DarkBackground"
backgrounds["npc_dota_hero_mirana"] = "WaterBackground"
backgrounds["npc_dota_hero_warlock"] = "FireBackground"
backgrounds["npc_dota_hero_lone_druid"] = "NatureBackground"
backgrounds["npc_dota_hero_earthshaker"] = "EarthBackground"

function HighlightSelectedBuilder () {
    var hero =  Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer())
    var heroName = Entities.GetUnitName(hero)

    for (var name in backgrounds)
    {
        if (name == heroName)
            Hovering(backgrounds[name])
        else if (! $("#"+name).hovering)
            HoverOut(backgrounds[name])
    }
    $.Schedule(1, HighlightSelectedBuilder)
}

HighlightSelectedBuilder()