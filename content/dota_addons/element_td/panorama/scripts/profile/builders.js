function AnimateBuilders() {
    $.DispatchEvent("DOTAGlobalSceneFireEntityInput", "LightBuilder", "donkey", "SetAnimation", "spawn");
    $.DispatchEvent("DOTAGlobalSceneFireEntityInput", "DarkBuilder", "rex", "SetAnimation", "courier_spawn");
    $.DispatchEvent("DOTAGlobalSceneFireEntityInput", "WaterBuilder", "puppey", "SetAnimation", "spawn");
    $.DispatchEvent("DOTAGlobalSceneFireEntityInput", "FireBuilder", "hellsworn", "SetAnimation", "golem_spawn");
    //$.DispatchEvent("DOTAGlobalSceneFireEntityInput", "NatureBuilder", "otter", "SetAnimation", "spawn");
    $.DispatchEvent("DOTAGlobalSceneFireEntityInput", "EarthBuilder", "armadillo", "SetAnimation", "spawn");
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
    
