"use strict";

var statsURL = 'http://hatinacat.com/leaderboard/data_request.php?req=stats&id='
var friendsURL = 'http://hatinacat.com/leaderboard/data_request.php?req=friends&id='
var ranksURL = 'http://hatinacat.com/leaderboard/data_request.php?req=player&ids='
var friendsPanel = $("#FriendsContainer")
var friendsLoaded = false;
var friendsRank = 0

function GetStats(steamID32) {
    $.Msg("Getting stats data for "+steamID32+"...")

    $.AsyncWebRequest( statsURL+steamID32, { type: 'GET', 
        success: function( data ) {
            var info = JSON.parse(data);
            var player_info = info["player"]

            var allTime = player_info["allTime"]
            if (allTime === undefined)
                return

            $("#GamesWon").text = allTime["gamesWon"]
            $("#BestScore").text = GameUI.FormatScore(allTime["bestScore"])

            // General
            $("#kills").text = GameUI.FormatKills(allTime["kills"])
            $("#frogKills").text = GameUI.FormatKills(allTime["frogKills"])
            $("#networth").text = GameUI.FormatGold(allTime["networth"])
            $("#interestGold").text = GameUI.FormatGold(allTime["interestGold"])
            $("#cleanWaves").text = allTime["cleanWaves"]
            $("#under30").text = allTime["under30"]

            // GameMode
            var normal = allTime["normal"]
            var hard = allTime["hard"]
            var veryhard = allTime["veryhard"]
            var insane = allTime["insane"]
            var total_matches = normal+hard+veryhard+insane
            BarStyle("normal", normal, total_matches)
            BarStyle("hard", hard, total_matches)
            BarStyle("veryhard", veryhard, total_matches)
            BarStyle("insane", insane, total_matches)
            
            // Element Usage
            var light = allTime["light"]
            var dark = allTime["dark"]
            var water = allTime["water"]
            var fire = allTime["fire"]
            var nature = allTime["nature"]
            var earth = allTime["earth"]
            var total_elem = light+dark+water+fire+nature+earth
            var favorite = allTime["favouriteElement"]

            var nextStart = 0
            nextStart = RadialStyle("light", nextStart, light/total_elem)
            nextStart = RadialStyle("dark", nextStart, dark/total_elem)
            nextStart = RadialStyle("water", nextStart, water/total_elem)
            nextStart = RadialStyle("fire", nextStart, fire/total_elem)
            nextStart = RadialStyle("nature", nextStart, nature/total_elem)
            nextStart = RadialStyle("earth", nextStart, earth/total_elem)

            var random = allTime["random"]
            $("#random").text = random+" ("+(random/total_matches*100).toFixed(0)+"%)"

            $("#"+favorite+"_usage").GetParent().AddClass("MostUsed")
        }
    })

    GetRank(steamID32, 0, "ClassicRank")
    GetRank(steamID32, 1, "ExpressRank")
    //GetRank(steamID32, 2, "FrogsRank") // Classic Rank request
}

function BarStyle(panelName, cant, total) {
    var percent = (cant/total*100)
    var panel = $("#"+panelName)
    panel.percent = percent
    if (percent < 10) percent=10
    panel.style['width'] = percent+"%;"
    panel.text = cant
}

function HoverDiff (name) {
    var panel = $("#"+name)
    $.DispatchEvent("DOTAShowTitleTextTooltip", panel, "#difficulty_"+name, parseInt(panel.percent).toFixed(0)+"% games");
}

function RadialStyle (panelName, start, percent) {
    var angle = percent*360
    $.Msg("Radial Style of "+angle.toFixed(1)+" from "+start)
    
    $("#"+panelName).style["clip"] = "radial( 50% 50%,"+start+"deg, "+angle+"deg );"
    $("#"+panelName+"_usage").text = (percent*100).toFixed(1)+"%"

    return start+angle
}

function GetRank (steamID32, leaderboard_type, panelName) {
    $.AsyncWebRequest( ranksURL+steamID32+"&lb="+leaderboard_type, { type: 'GET', 
        success: function( data ) {

            var info = JSON.parse(data);
            var players_info = info["players"]

            for (var i in players_info)
            {
                $("#"+panelName).text = GameUI.FormatRank(players_info[i].rank);
            }
        }
    })
}

function GetPlayerFriends(steamID64) {
    $.Msg("Getting friends data for "+steamID64+"...")

    var delay = 0
    var delay_per_panel = 0.1;

    $.AsyncWebRequest( friendsURL+steamID64, { type: 'GET', 
        success: function( data ) {
            friendsLoaded = true;
            var info = JSON.parse(data);
            var players_info = info["players"]
            
            // Sort by rank
            players_info.sort(function(a, b) {
                return parseInt(a.rank) - parseInt(b.rank);
            });

            for (var i in players_info)
            {
                var callback = function( data )
                {
                    return function(){ CreateFriendPanel(data) }
                }( players_info[i] );

                $.Schedule( delay, callback )
                delay += delay_per_panel;
            }
        }
    })
}

function CreateFriendPanel(data) {
    friendsRank++

    var steamID64 = GameUI.ConvertID64(data.steamID)
    var playerPanel = $.CreatePanel("Panel", friendsPanel, "Friend_"+steamID64)
    playerPanel.steamID = steamID64
    playerPanel.score = GameUI.FormatScore(data.score)
    playerPanel.friendRank = friendsRank
    playerPanel.rank = GameUI.FormatRank(data.rank)
    playerPanel.percentile = GameUI.FormatPercentile(data.percentile)
    playerPanel.BLoadLayout("file://{resources}/layout/custom_game/profile_friend.xml", false, false);

    var steamID = GameUI.GetLocalPlayerSteamID()
    if (steamID64 == steamID)
        playerPanel.AddClass("local")
}

function ToggleProfile() {
    $("#Profile").ToggleClass("Hide")
}

function MakeButtonVisible() {
    var bShowProfile = GameUI.PlayerHasProfile(Game.GetLocalPlayerID())
    $("#ProfileToggleContainer").SetHasClass("Hide", !bShowProfile)
}

function Setup() {
    var steamID64 = GameUI.GetLocalPlayerSteamID() //34961594
    var steamID32 = GameUI.ConvertID32(steamID64)
    $("#AvatarImageMini").steamid = steamID64
    $("#AvatarImageProfile").steamid = steamID64
    $("#UserNameProfile").steamid = steamID64

    GetStats(steamID32)
    GetPlayerFriends(steamID32)
}

(function () {
    $.Schedule(0.1, MakeButtonVisible)
    $.Schedule(0.1, Setup)

    $("#Profile").ToggleClass("Hide")
})();