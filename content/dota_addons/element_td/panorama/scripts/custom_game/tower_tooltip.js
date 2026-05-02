var tooltipUI = $("#TowerTooltip")

function GetSelectedTower()
{
    var mainSelected = Players.GetLocalPlayerPortraitUnit()
    if (mainSelected == -1)
        return null

    var unitName = Entities.GetUnitName(mainSelected)
    if (!unitName || unitName.indexOf("tower") <= -1)
        return null

    return {entityIndex: mainSelected, unitName: unitName}
}

function ShowTowerTooltip()
{
    // Exit out of multiple tower selection
    var selectedEntities = Players.GetSelectedEntities(Game.GetLocalPlayerID());
    if (selectedEntities.length > 1)
    {
        tooltipUI.hittest = false
        return
    }

    var selectedTower = GetSelectedTower()
    if (!selectedTower)
        return

    var mainSelected = selectedTower.entityIndex
    var unitName = selectedTower.unitName
    var attacksPerSecond = Entities.GetAttacksPerSecond(mainSelected).toFixed(1)
    var range = Entities.GetAttackRange(mainSelected)
    var bat = Entities.GetBaseAttackTime(mainSelected).toFixed(2)
    var tooltip = "<b>" + $.Localize("#tower_tooltip_attacks_per_second") + ": </b>" + attacksPerSecond

    var ias = Math.round(Entities.GetIncreasedAttackSpeed(mainSelected) * 100)
    if (ias>0)
        tooltip+="<br><b>" + $.Localize("#tower_tooltip_attack_speed") + ": </b>+" + ias

    tooltip+= "<br><b>" + $.Localize("#tower_tooltip_bat") + ": </b>" + bat
    tooltip+= "<br><b>" + $.Localize("#tower_tooltip_range") + ": </b>" + range
    
    var towerTable = CustomNetTables.GetTableValue( "towers", unitName)
    if (towerTable)
    {
        var AOE_Full = Number(towerTable.AOE_Full)
        var AOE_Half = Number(towerTable.AOE_Half)
        tooltip+= "<br><b>" + $.Localize("#tower_tooltip_aoe") + ":</b> " + AOE_Full + " (" + $.Localize("#tower_tooltip_full") + ")/" + AOE_Half + " (" + $.Localize("#tower_tooltip_half") + ")"
    }
    var targetingTable = CustomNetTables.GetTableValue("tower_targeting", String(mainSelected))
    if (targetingTable && targetingTable.text)
    {
        tooltip+= "<br>" + $.Localize(targetingTable.text)
    }

    $.DispatchEvent("DOTAShowTitleTextTooltip", tooltipUI, $.Localize("#" + unitName), tooltip);
}

function OnUpdateSelectedUnit() {
    var selectedTower = GetSelectedTower()
    tooltipUI.SetHasClass("Hidden", !selectedTower)
    tooltipUI.hittest = true
}

function OnUpdateQueryUnit() {
    tooltipUI.SetHasClass("Hidden", !GetSelectedTower())
}

(function () {
    $.Msg("Tower Tooltip loaded")
    GameEvents.Subscribe( "dota_player_update_selected_unit", OnUpdateSelectedUnit );
    GameEvents.Subscribe( "dota_player_update_query_unit", OnUpdateQueryUnit );
})();
