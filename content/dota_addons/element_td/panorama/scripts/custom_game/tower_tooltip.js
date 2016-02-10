var tooltipUI = $("#TowerTooltip")

function ShowTowerTooltip()
{
    var mainSelected = Players.GetLocalPlayerPortraitUnit();
    var unitName = Entities.GetUnitName(mainSelected)
    var attacksPerSecond = Entities.GetAttacksPerSecond(mainSelected).toFixed(1)
    var range = Entities.GetAttackRange(mainSelected)
    var bat = Entities.GetBaseAttackTime(mainSelected).toFixed(2)
    var tooltip = "<b>Attacks/sec: </b>"+attacksPerSecond

    var ias = Math.round(Entities.GetIncreasedAttackSpeed(mainSelected) * 100)
    if (ias>0)
        tooltip+="<br><b>Attack speed: </b>+"+ias

    tooltip+= "<br><b>BAT: </b>"+bat+"<br><b>Range: </b>"+range
    
    var towerTable = CustomNetTables.GetTableValue( "towers", unitName)
    if (towerTable)
    {
        var AOE_Full = Number(towerTable.AOE_Full)
        var AOE_Half = Number(towerTable.AOE_Half)
        tooltip+= "<br><b>AOE:</b> "+AOE_Full+"(Full)/"+AOE_Half+"(Half)"
    }
    $.DispatchEvent("DOTAShowTitleTextTooltip", tooltipUI, unitName, tooltip);
}

function OnUpdateSelectedUnit() {
    var mainSelected = Players.GetLocalPlayerPortraitUnit()
    var unitName = Entities.GetUnitName(mainSelected)
    tooltipUI.SetHasClass("Hidden", unitName.indexOf("tower") <= -1)
}

function OnUpdateQueryUnit() {
    var mainSelected = Players.GetLocalPlayerPortraitUnit()
    var unitName = Entities.GetUnitName(mainSelected)
    tooltipUI.SetHasClass("Hidden", unitName.indexOf("tower") <= -1)
}

(function () {
    $.Msg("Tower Tooltip loaded")
    GameEvents.Subscribe( "dota_player_update_selected_unit", OnUpdateSelectedUnit );
    GameEvents.Subscribe( "dota_player_update_query_unit", OnUpdateQueryUnit );
})();