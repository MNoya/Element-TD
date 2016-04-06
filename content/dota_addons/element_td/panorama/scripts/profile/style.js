function ClearFields() {
    $("#GamesWon").text = "-"
    $("#BestScore").text = "-"

    // General
    $("#kills").text = "-"
    $("#frogKills").text = "-"
    $("#networth").text = "-"
    $("#interestGold").text = "-"
    $("#cleanWaves").text = "-"
    $("#under30").text = "-"

    // GameMode
    var data = []
    data["gamesPlayed"] = 4
    data["normal"] = 1
    data["hard"] = 1
    data["veryhard"] = 1
    data["insane"] = 1
    data["order_chaos"] = 0
    data["horde_endless"] = 0
    data["express"] = 0

    MakeBars(data, ["normal","hard","veryhard","insane"])
    MakeBoolBar(data, "order_chaos")
    MakeBoolBar(data, "horde_endless")
    MakeBoolBar(data, "express")

    var random = "-"
    $("#gamesPlayed").text = 0
    $("#random_pick").text = "-"
    $("#towersBuilt").text = "-"
    $("#towersSold").text = "-"
    $("#lifeTowerKills").text = "-"
    $("#goldTowerEarn").text = "-"

    // Towers
    MakeFirstDual("")
    MakeFirstTriple("")

    // Element Usage
    var light = 1
    var dark = 1
    var water = 1
    var fire = 1
    var nature = 1
    var earth = 1
    var total_elem = light+dark+water+fire+nature+earth
    var favorite = "-"

    var nextStart = 0
    nextStart = RadialStyle("light", nextStart, light/total_elem)
    nextStart = RadialStyle("dark", nextStart, dark/total_elem)
    nextStart = RadialStyle("water", nextStart, water/total_elem)
    nextStart = RadialStyle("fire", nextStart, fire/total_elem)
    nextStart = RadialStyle("nature", nextStart, nature/total_elem)
    nextStart = RadialStyle("earth", nextStart, earth/total_elem)

    $("#ClassicRank").text = "--"
    $("#ExpressRank").text = "--"
    $("#FrogsRank").text = "--"

    // Milestones
    var childCount = $("#MilestonesContainer").GetChildCount()
    for (var i = 0; i < childCount; i++) {
        var child = $("#MilestonesContainer").GetChild(i)
        if (child && child.id != "ErrorNoMilestones") child.DeleteAsync(0)
    };

    // Matches
    var childCount = $("#MatchesContainer").GetChildCount()
    for (var i = 0; i < childCount; i++) {
        var child = $("#MatchesContainer").GetChild(i)
        if (child && child.id != "ErrorNoMatches") child.DeleteAsync(0)
    };
}

// RandomGameUI.FormatNumber( data)
function SetPreviewProfile() {
    $.Msg("Setting Preview Profile")

    var steamID64 = "76561198077142019" //Our Element TD dummy account
    $("#AvatarImageProfile").steamid = steamID64
    $("#UserNameProfile").steamid = steamID64

    $("#ProfileBackContainer").SetHasClass("Hide", true)
    $("#UserNameProfile").SetHasClass("selfName", true)
    $("#UserNameProfile").SetHasClass("friendName", false)

    $("#GamesWon").text = "-"
    $("#BestScore").text = "-"

    // General
    $("#kills").text = GameUI.FormatNumber("1337")
    $("#frogKills").text = GameUI.FormatNumber("4200000")
    $("#networth").text = GameUI.FormatGold("9999999")
    $("#interestGold").text = GameUI.FormatGold("322000")
    $("#cleanWaves").text = GameUI.FormatNumber("4200")
    $("#under30").text = GameUI.FormatNumber("3000")

    // GameMode
    var data = []
    data["gamesPlayed"] = 110
    data["normal"] = 50
    data["hard"] = 30
    data["veryhard"] = 10
    data["insane"] = 20
    data["order_chaos"] = 15
    data["horde_endless"] = 45
    data["express"] = 20

    MakeBars(data, ["normal","hard","veryhard","insane"])
    MakeBoolBar(data, "order_chaos")
    MakeBoolBar(data, "horde_endless")
    MakeBoolBar(data, "express")

    var random = RandomInt(30, 50)
    $("#gamesPlayed").text = GameUI.FormatNumber("100")
    $("#random_pick").text = random+" ("+(random/data["gamesPlayed"]*100).toFixed(0)+"%)"
    $("#towersBuilt").text = GameUI.FormatNumber("1000")
    $("#towersSold").text = GameUI.FormatNumber("100")
    $("#lifeTowerKills").text = GameUI.FormatNumber("5000")
    $("#goldTowerEarn").text = GameUI.FormatGold("9999999")

    // Towers
    MakeFirstDual(pickRandomProperty(duals))
    MakeFirstTriple(pickRandomProperty(triples))

    // Element Usage
    var light = RandomInt(50, 100)
    var dark = RandomInt(50, 100)
    var water = RandomInt(50, 100)
    var fire = RandomInt(50, 100)
    var nature = RandomInt(50, 100)
    var earth = RandomInt(50, 100)
    var total_elem = light+dark+water+fire+nature+earth
    var favorite = "-"

    var nextStart = 0
    nextStart = RadialStyle("light", nextStart, light/total_elem)
    nextStart = RadialStyle("dark", nextStart, dark/total_elem)
    nextStart = RadialStyle("water", nextStart, water/total_elem)
    nextStart = RadialStyle("fire", nextStart, fire/total_elem)
    nextStart = RadialStyle("nature", nextStart, nature/total_elem)
    nextStart = RadialStyle("earth", nextStart, earth/total_elem)

    $("#ClassicRank").text = "--"
    $("#ExpressRank").text = "--"
    $("#FrogsRank").text = "--"

    // Milestones
    var childCount = $("#MilestonesContainer").GetChildCount()
    for (var i = 0; i < childCount; i++) {
        var child = $("#MilestonesContainer").GetChild(i)
        if (child && child.id != "ErrorNoMilestones") child.DeleteAsync(0)
    };

    // Matches
    var childCount = $("#MatchesContainer").GetChildCount()
    for (var i = 0; i < childCount; i++) {
        var child = $("#MatchesContainer").GetChild(i)
        if (child && child.id != "ErrorNoMatches") child.DeleteAsync(0)
    };

    ShowFriendRanks("classic", GameUI.ConvertID32(steamID64))
}


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
        if (dual_string != "")
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
        if (triple_string != "")
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

function pickRandomProperty(obj) {
    var result;
    var count = 0;
    for (var prop in obj)
        if (Math.random() < 1/++count)
           result = prop;
    return result;
}

function RandomInt(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
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