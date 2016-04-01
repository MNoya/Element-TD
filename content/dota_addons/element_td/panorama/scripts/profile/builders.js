function CreateBuilders () {   
    Load($('#LightBuilder'), "npc_dota_hero_keeper_of_the_light")
    Load($('#DarkBuilder'), "npc_dota_hero_faceless_void")
    Load($('#WaterBuilder'), "npc_dota_hero_mirana")
    Load($('#FireBuilder'), "npc_dota_hero_phoenix")
    Load($('#NatureBuilder'), "npc_dota_hero_treant")
    Load($('#EarthBuilder'), "armadillo")
}

function Load(panel, heroName) {
    panel.BLoadLayoutFromString(
    '<root>
        <Panel>
            <DOTAScenePanel class="BuilderPanel" unit="'+heroName+'"/>
        </Panel>
    </root>', false, false );
}

function ChooseBuilder(heroName) {
    GameEvents.SendCustomGameEventToServer( "player_choose_custom_builder", { "hero_name": heroName } );
    CloseCustomBuilders()
}

CreateBuilders()