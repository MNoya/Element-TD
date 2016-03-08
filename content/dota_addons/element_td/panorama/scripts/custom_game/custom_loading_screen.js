var transition_time = 2
var time_per_tip = 15
var count = CountTips();
var currentTip = -1;

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
    var str = $.Localize("loading_screen_tip_"+random_number);
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
        var tip = $.Localize("loading_screen_tip_"+(i+1))
        if (tip == "loading_screen_tip_"+(i+1)){
            return i;
            break;
        };
    };
};

(function () {
    $.Schedule(45, ShowTips);
})();