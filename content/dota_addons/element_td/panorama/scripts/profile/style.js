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

// Recieved String order is alphabetical: Dark-Earth-Fire-Light-Nature-Water
function MakeFirstDual (dual_string) {
    var dual = duals[dual_string]
    if (dual)
    {
        $("#dual").text = $.Localize(dual+"_tower_name")
        $("#dual_image").SetImage( "file://{images}/spellicons/towers/"+dual+".png" );
        $("#FirstDualPanel").SetPanelEvent( "onmouseover", function() {
            var tooltip_name = "item_upgrade_to_"+dual+"_tower"
            $.DispatchEvent( "DOTAShowAbilityTooltip", $("#FirstDualPanel"), tooltip_name);
        })
        $("#FirstDualPanel").SetPanelEvent( "onmouseout", function() {
            $.DispatchEvent( "DOTAHideAbilityTooltip", $("#FirstDualPanel") );
        })
    }
    else
    {
        $("#dual").text = "-"
        $("#dual_image").SetImage("");
        $.Msg("Missing dual for: "+dual_string)
    }
}

function MakeFirstTriple (triple_string) {
    var triple = triples[triple_string]
    if (triple)
    {
        $("#triple").text = $.Localize(triple+"_tower_name")
        $("#triple_image").SetImage( "file://{images}/spellicons/towers/"+triple+".png" );
    }
    else
    {
        $("#triple").text = "-"
        $("#triple_image").SetImage("");
        $.Msg("Missing triple for: "+triple_string)
    }

    $("#FirstTriplePanel").SetPanelEvent( "onmouseover", function() {
            var tooltip_name = "item_upgrade_to_"+triple+"_tower"
            $.DispatchEvent( "DOTAShowAbilityTooltip", $("#FirstTriplePanel"), tooltip_name);
        })
        $("#FirstTriplePanel").SetPanelEvent( "onmouseout", function() {
            $.DispatchEvent( "DOTAHideAbilityTooltip", $("#FirstTriplePanel") );
        })
}

var duals = {}
// Light
duals["Light+Water"] = 'ice'
duals["Dark+Light"] = 'trickery'

// Dark
duals["Dark+Nature"] = 'disease'
duals["Dark+Fire"] = 'magic'

// Water
duals["Fire+Water"] = 'vapor'
duals["Nature+Water"] = 'well'
duals["Dark+Water"] = 'poison'

// Fire
duals["Earth+Fire"] = 'blacksmith'
duals["Fire+Nature"] = 'flame'
duals["Fire+Light"] = 'electricity'

// Nature
duals["Light+Nature"] = 'life'
duals["Earth+Nature"] = 'moss'

// Earth
duals["Dark+Earth"] = 'gunpowder'
duals["Earth+Water"] = 'hydro'
duals["Earth+Light"] = 'quark'

var triples = {}
// Light
triples["Dark+Light+Water"] = 'hail'
triples["Fire+Light+Nature"] = 'nova'
triples["Dark+Earth+Light"] = 'laser'

// Dark
triples["Dark+Fire+Nature"] = 'jinx'
triples["Dark+Fire+Light"] = 'runic'
triples["Dark+Nature+Light"] = 'obliteration'

// Water
triples["Fire+Light+Water"] = 'windstorm'
triples["Dark+Nature+Water"] = 'flooding'
triples["Earth+Light+Water"] = 'polar'
triples["Light+Nature+Water"] = 'tidal'

// Fire
triples["Earth+Fire+Water"] = 'haste'
triples["Dark+Fire+Earth"] = 'flamethrower'
triples["Dark+Fire+Water"] = 'erosion'

// Nature
triples["Fire+Nature+Water"] = 'impulse'
triples["Dark+Earth+Nature"] = 'roots'
triples["Earth+Nature+Water"] = 'ephemeral'
triples["Earth+Light+Nature"] = 'enchantment'

// Earth
triples["Earth+Fire+Light"] = 'gold'
triples["Earth+Fire+Nature"] = 'quake'
triples["Dark+Earth+Water"] = 'muck'


// SOUND LIST
/*
    ui_generic_button_click
    ui_custom_lobby_drawer_slide_in
    ui_custom_lobby_drawer_slide_out
    ui_friends_slide_in
    ui_hero_select_slide
    ui_hero_select_slide_late
    ui_custom_lobby_dialog_slide
    ui_custom_lobby_dialog_cancel
    ui_team_select_shuffle
    ui_team_select_auto_assign
    ui_quit_menu_fadeout
    ui.menu_quit
    ui_settings_multi
    ui_topmenu_activate
    ui_find_match_slide_out
    ui_find_match_slide_in
    ui_select_blue
    ui_rollover_micro
    ui_select_arrow
    ui_settings_out_multi
    ui_goto_player_page
    ui_hero_hat_select
*/