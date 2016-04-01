function CreateBuilders () {   
    Load($('#LightBuilder'), "npc_dota_hero_chen")
    Load($('#DarkBuilder'), "npc_dota_hero_faceless_void")
    Load($('#WaterBuilder'), "npc_dota_hero_mirana")
    Load($('#FireBuilder'), "npc_dota_hero_warlock")
    Load($('#NatureBuilder'), "npc_dota_hero_furion")
    Load($('#EarthBuilder'), "npc_dota_hero_earthshaker")
    $.GetContextPanel().created = true
}

function Load(panel, heroName) {
    panel.BLoadLayoutFromString('<root><styles><include src="file://{resources}/styles/custom_game/profile.css"/></styles><Panel><DOTAScenePanel class="BuilderPanel" unit="'+heroName+'"/></Panel></root>', false, false );
}

function Hovering(name) {
    $("#"+name).AddClass("Hovering")
}

function HoverOut(name) {
    $("#"+name).RemoveClass("Hovering")
}

function ChooseBuilder(heroName) {
    GameEvents.SendCustomGameEventToServer( "player_choose_custom_builder", { "hero_name": heroName } );
    CloseCustomBuilders()
}
    
