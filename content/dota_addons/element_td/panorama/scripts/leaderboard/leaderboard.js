var Leaderboard = $("#Leaderboard")
var Buttons = $("#Buttons")
var url = "http://hatinacat.com/leaderboard/data_request.php?req=leaderboard"
var CLASSIC = 0
var EXPRESS = 2
var FROGS = 3
var LEADERBOARD_THRESHOLD = 300
var REFRESH_THRESHOLD = 3
var lastRequest
var lastRefresh

function GetTopRanks(type, num, panel) {
    var top = url+"&top="+num+"&lb="+type
    $.AsyncWebRequest( top, { type: 'GET', 
        success: function( data ) {
            var info = JSON.parse(data);
            var players = info['players']

            //$.Msg(panel.id)
            for (var steamID in players)
            {
                //$.Msg("Top "+players[steamID]['rank']+":", players[steamID])
                CreateTopPlayerPanel(players[steamID], panel)
            }
        }
    })
}

function CreateTopPlayerPanel(data, panel) {
    var steamID64 = ConvertID64(data.steamID)
    var playerPanel = $.CreatePanel("Panel", panel, "Top_"+panel.id+"_"+steamID64)
    playerPanel.steamID = steamID64
    playerPanel.score = FormatScore(data.score)
    playerPanel.rank = data.rank
    playerPanel.frogs = data.icefrog
    playerPanel.BLoadLayout("file://{resources}/layout/custom_game/leaderboard_player.xml", false, false);

    var playerInfo = Game.GetLocalPlayerInfo()
    if (playerInfo & steamID64 == playerInfo.steamid)
        playerPanel.AddClass("local")
}

function ConvertID64 (steamID32) {
    return '765'+(parseInt(steamID32) + 61197960265728)
}

// Format score in k (thousands) format
function FormatScore(score) {
    return score.substring(0, score.length-3)+"k";
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
    GetTopRanks(CLASSIC, 10, $("#ClassicLeaderboard"))
    GetTopRanks(EXPRESS, 10, $("#ExpressLeaderboard"))
    GetTopRanks(FROGS, 10, $("#FrogsLeaderboard"))
}

function RefreshAllRanks()
{
    // Protect against refresh spam
    var timeNow = Game.Time()
    if (lastRefresh === undefined)
        lastRefresh = timeNow
    else if (timeNow-lastRefresh < REFRESH_THRESHOLD)
        return

    lastRefresh = timeNow
    $.Msg("Reseting All Ranks")
    Refresh(CLASSIC, "ClassicLeaderboard")
    Refresh(EXPRESS, "ExpressLeaderboard")
    Refresh(FROGS, "FrogsLeaderboard")
}

function Refresh(leaderboard_type, id) {
    ClearRanks($("#"+id))
    GetTopRanks(leaderboard_type, 10, $("#"+id))
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

// Only setup at request
function ToggleLeaderboard()
{
    Leaderboard.ToggleClass("Hide")
    Buttons.ToggleClass("Hide")
    if (!Leaderboard.BHasClass("Hide"))
        Setup()
}