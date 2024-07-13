var transition_time = 2
var time_per_tip = 20
var count = CountTips();
var currentTip = -1;

$.Msg( "Compiled Panorama Loading Screen!" );

function ShowTips(){
    var random_number = Math.floor(Math.random() * count);
    
    // Random again if the number is the same
    if (random_number == currentTip)
    {
        ShowTips()
        return
    }

    // accepted random localized string;
    currentTip = random_number
    var str = $.Localize("#loading_screen_tip_"+random_number);
    var tip = $("#Tip")
    tip.text = str;
    tip.RemoveClass("Hide")
    tip.AddClass("Show")
    
    $.Schedule(time_per_tip, function(){
        tip.RemoveClass("Show")
        tip.AddClass("Hide")
    })

    $.Schedule(time_per_tip+transition_time, ShowTips)
};

function CountTips(){
    for(i=0;;i++)
    {
        var tip = $.Localize("#loading_screen_tip_"+(i+1))
        if (tip == "#loading_screen_tip_"+(i+1)){
            return i;
            break;
        };
    };
};

function ChooseBackground() {
    var mapInfo = Game.GetMapInfo()
    var mapName = mapInfo.map_display_name

    if (mapName == "")
    {
        $.Schedule(0.1, ChooseBackground);
        return;
    }

    if (mapName == "element_td_coop")
    {
        $("#seq_bg").style["background-image"] = "url('file://{images}/custom_game/loading_screen/coop_background.png');";
        $("#seq_light").visible = false;
        $("#seq_dark").visible = false;
        $("#seq_water").visible = false;
        $("#seq_fire").visible = false;
        $("#seq_nature").visible = false;
        $("#seq_earth").visible = false;
        //$("#Promote").visible = false;
        $.Msg("Changed loading screen to coop loading")
    }
};


(function () {
    ShowTips()
    ChooseBackground()
})();