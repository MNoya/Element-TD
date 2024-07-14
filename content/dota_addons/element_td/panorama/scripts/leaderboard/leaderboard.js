var Leaderboard = $("#Leaderboard")
var Buttons = $("#Buttons")
var url = "http://hatinacat.com/leaderboard/data_request.php?req=leaderboard"
var CLASSIC = 0
var EXPRESS = 2
var FROGS = 3
var COOP = 4
var LEADERBOARD_THRESHOLD = 300
var MAX_RANKS = 100
var REFRESH_THRESHOLD = 10
var lastRequest
var lastRefresh

function GetTopRanks(type) {
    GameEvents.SendCustomGameEventToServer( "etd_leaderboard_request", { 'leaderboard_type': type } )
}

function OnTopRanks(data) {
    var info = data

    var type = info['type']
    var panel = null

    if (type == CLASSIC) {
        panel = $("#ClassicLeaderboardContainer")
    } else if (type == EXPRESS) {
        panel = $("#ExpressLeaderboardContainer")
    } else if (type == FROGS) {
        panel = $("#FrogsLeaderboardContainer")
    } else if (type == COOP) {
        panel = $("#CoopLeaderboardContainer")
    } else {
        return
    }
    
    var players = info['players']
    var matches = info['matches']

    var delay = 0
    var delay_per_panel = 0.05

    var loadingSpinner = $("#Loading"+type)
    loadingSpinner.RemoveClass("Hide")

    if (players === undefined && matches === undefined)
    {
        $.Msg("Error on GetTopRanks "+type)
        loadingSpinner.AddClass("Hide")
        $("#ErrorLB"+type).RemoveClass("Hide")
        return
    }

    if (type == COOP)
    {
        panel.ranks = 0
        matches = SortCoopMatches(matches)
        for (var matchID in matches)
        {
            var callback = function( data, panel )
            {
                return function(){ CreateTopTeamPanel(data, panel); }
            }( matches[matchID], panel );

            $.Schedule( delay, callback )
            delay += delay_per_panel;
        }
    }
    else
    {
        for (var steamID in players)
        {
            //$.Msg("Top "+players[steamID]['rank']+":", players[steamID])
            var callback = function( data, panel )
            {
                return function(){ CreateTopPlayerPanel(data, panel); }
            }( players[steamID], panel );

            $.Schedule( delay, callback )
            delay += delay_per_panel;
        }
    }
    
    loadingSpinner.AddClass("Hide")
    $("#ErrorLB"+type).AddClass("Hide")
}

function CreateTopPlayerPanel(data, panel) {
    var steamID64 = GameUI.ConvertID64(data.steamID)
    var playerPanel = $.CreatePanel("Panel", panel, "Top_"+panel.id+"_"+steamID64)
    playerPanel.steamID = steamID64
    playerPanel.score = GameUI.FormatScore(data.score)
    playerPanel.rank = data.rank
    playerPanel.frogs = data.icefrog
    playerPanel.BLoadLayout("file://{resources}/layout/custom_game/leaderboard_player.xml", false, false);

    var playerID = Game.GetLocalPlayerID()
    var localSteamID = GameUI.GetPlayerSteamID(playerID)
    if (steamID64 == localSteamID)
        playerPanel.AddClass("local")

    GameUI.SetupAvatarTooltip(playerPanel.FindChildInLayoutFile("AvatarImage"), $.GetContextPanel(), steamID64)
}

function CreateTopTeamPanel(data, panel) {
    panel.ranks++

    var teamPanel = $.CreatePanel("Panel", panel, "Top_"+panel.id+"_"+panel.ranks)
    teamPanel.rank = panel.ranks
    teamPanel.players = []
    teamPanel.playerCount = 0

    var playerID = Game.GetLocalPlayerID()
    var localSteamID = GameUI.GetPlayerSteamID(playerID)

    for (var i in data)
    {
        if (data[i].steamID)
        {
            teamPanel.playerCount++
            var steamID64 = GameUI.ConvertID64(data[i].steamID)
            teamPanel.players[teamPanel.playerCount] = steamID64

            if (steamID64 == localSteamID)
                teamPanel.AddClass("local")

            if (teamPanel.score === undefined)
                teamPanel.score = GameUI.FormatScore(data[i].score)

            if (teamPanel.wave === undefined)
                teamPanel.wave = data[i].wave
        }
    }

    teamPanel.BLoadLayout("file://{resources}/layout/custom_game/leaderboard_team.xml", false, false);
}

function Setup()
{
    var timeNow = Game.Time()
    if (lastRequest === undefined)
    {
        lastRequest = timeNow
        CreateAllRanks()
    }
    else if (timeNow-lastRequest > LEADERBOARD_THRESHOLD)
    {
        lastRequest = timeNow
        RefreshAllRanks()
    }
}

function CreateAllRanks() {
    var bCoop = Game.IsCoop()

    $("#ClassicLeaderboard").SetHasClass( "Hide", bCoop )
    $("#ExpressLeaderboard").SetHasClass( "Hide", bCoop )
    $("#FrogsLeaderboard").SetHasClass( "Hide", bCoop )
    $("#CoopLeaderboard").SetHasClass( "Hide", ! bCoop )
    
    if (bCoop)
    {
        $("#Buttons").AddClass("Coop")
        $("#LeaderboardLink").AddClass("Coop")
        Leaderboard.AddClass("Coop")
        GetTopRanks(COOP)
    }
    else
    {
        GetTopRanks(CLASSIC)
        GetTopRanks(EXPRESS)
        GetTopRanks(FROGS)
    }
}

function RefreshAllRanks()
{
    // Protect against refresh spam
    var timeNow = Game.Time()
    if (lastRefresh === undefined)
    {
        lastRefresh = timeNow
        return
    }
    else if (timeNow-lastRefresh < REFRESH_THRESHOLD)
        return

    lastRefresh = timeNow
    $.Msg("Reseting All Ranks")
    if (Game.IsCoop())
        Refresh(COOP, "CoopLeaderboardContainer")
    else
    {
        Refresh(CLASSIC, "ClassicLeaderboardContainer")
        Refresh(EXPRESS, "ExpressLeaderboardContainer")
        Refresh(FROGS, "FrogsLeaderboardContainer")
    }
}

function Refresh(leaderboard_type, id) {
    ClearRanks($("#"+id))
    GetTopRanks(leaderboard_type)
}

function ClearRanks(panel) {
    var childN = panel.GetChildCount()
    for (var i = 0; i < childN; i++) {
        var child = panel.GetChild( i )
        if (child.id.indexOf(panel.id) != -1)
        {
            child.DeleteAsync(0)
        }
    }
}

function SortCoopMatches(data) {
    var matches = []
    for (var x = 0; x < 100; x++) 
    {
        var max = 0
        var id = 0
        for (var i in data) 
        {
            if (data[i].processed === undefined)
            {
                for (var e in data[i]) {
                    var entry = data[i][e]
                    if (entry.score && entry.score > max)
                    {
                        max = entry.score
                        id = i
                    }
                } 
            }  
        }
        matches.push(data[id])
        data[id].processed = true;
    }

    return matches;
}


GameUI.CloseLeaderboard = function() {
    Leaderboard.AddClass("Hide")
    Buttons.AddClass("Hide")
    $("#LeaderboardLink").AddClass("Hide")
}

// Only setup at request
function ToggleLeaderboard()
{
    Leaderboard.ToggleClass("Hide")
    $("#LeaderboardLink").ToggleClass("Hide")
    Buttons.ToggleClass("Hide")
    if (!Leaderboard.BHasClass("Hide"))
    {
        Setup()
        GameUI.CloseProfilePanels()
        GameUI.CloseTowerTable()
    }
    Game.EmitSound("ui_generic_button_click")
}

(function () {
    GameEvents.Subscribe( "etd_leaderboard_ranks", OnTopRanks);
})();