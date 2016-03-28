function MakeBoolBar(data, name) {
    var panel = $("#"+name)
    var not_panel = $("#not_"+name)

    var total = data["gamesPlayed"]
    var numValue = data[name] || 0
    var value = numValue / total * 100
    var not_value = 100 - value

    var maxWidth = 80
    if (value > maxWidth) value = maxWidth
    panel.style['width'] = value+"%;"
    panel.percent = value
    not_panel.text = numValue//value.toFixed(0)+"%"
}

// This requires that every entry on arrayNames has a panel bar with the same ID name
function MakeBars (data, arrayNames) {
    // Count total and setup widths
    var total = 0
    var list = {}
    for (var i = 0; i < arrayNames.length; i++) {
        var value = data[arrayNames[i]]
        list[arrayNames[i]] = value
        total+=value
    };

    // Sort by values and set bars
    var remaining = 100
    bySortedValue(list, function(key, value) {
        remaining -= BarStyle(key, value, total, remaining)
    });

    $("#gamesPlayed").text = GameUI.CommaFormat(total)
}

function bySortedValue(obj, callback, context) {
    var tuples = [];

    for (var key in obj) tuples.push([key, obj[key]]);

    tuples.sort(function(a, b) { return a[1] < b[1] ? 1 : a[1] > b[1] ? -1 : 0 });

    var length = tuples.length;
    while (length--) callback.call(context, tuples[length][0], tuples[length][1]);
}

function BarStyle(panelName, cant, total, remaining) {
    var percent = (cant/total*100)
    var minWidth = cant.toString().length * 5
    if (cant == 0) minWidth = 0
    var panel = $("#"+panelName)
    panel.percent = percent

    if (percent < minWidth)
        percent = minWidth

    if (percent > remaining)
        percent = remaining

    panel.style['width'] = percent+"%;"
    panel.text = cant

    return percent
}

function RadialStyle (panelName, start, percent) {
    var angle = percent*360
    
    $("#"+panelName).style["clip"] = "radial( 50% 50%,"+start+"deg, "+angle+"deg );"
    $("#"+panelName+"_usage").text = (percent*100).toFixed(1)+"%"

    return start+angle
}

function HoverDiff (name) {
    var panel = $("#"+name)
    $.DispatchEvent("DOTAShowTitleTextTooltip", panel, "#difficulty_"+name, parseInt(panel.percent).toFixed(0)+"% games");
}

function HoverPanel (name) {
    var panel = $("#"+name)
    $.DispatchEvent("DOTAShowTitleTextTooltip", panel, "#"+name, parseInt(panel.percent).toFixed(0)+"% games");
}

var piechart_names = ["light", "dark", "water", "fire", "nature", "earth"]
function HoverPieSector (name) {
    for (var i in piechart_names) {
        var panel = $("#"+piechart_names[i])
        if (piechart_names[i] == name)
        {
            panel.AddClass("Hover")
            $("#"+piechart_names[i]+"_usage").AddClass("Highlight")
            $("#"+piechart_names[i]+"_label").AddClass("Highlight")
        }
        else
            panel.AddClass("Desaturate")
    }
}

function MouseOverPie () {
    for (var i in piechart_names) {
        $("#"+piechart_names[i]).RemoveClass("Hover")
        $("#"+piechart_names[i]).RemoveClass("Desaturate")
        $("#"+piechart_names[i]+"_usage").RemoveClass("Highlight")
        $("#"+piechart_names[i]+"_label").RemoveClass("Highlight")
    }
}