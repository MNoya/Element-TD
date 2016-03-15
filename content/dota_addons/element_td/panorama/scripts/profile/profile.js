"use strict";

var friendsURL = 'http://hatinacat.com/leaderboard/data_request.php?req=friends&id='
var friendsPanel = $("#RightPanel")
var visible = false;

function GetPlayerFriends(playerID) {
    $.Msg("Getting player friends data...")
    var playerInfo = Game.GetPlayerInfo(playerID)
    var steamID = playerInfo.player_steamid
    $.AsyncWebRequest( friendsURL+steamID, { type: 'GET', 
        success: function( data ) {
            var info = JSON.parse(data);
            var players_info = info["players"]
            
            // Sort by rank
            players_info.sort(function(a, b) {
                return parseInt(a.rank) - parseInt(b.rank);
            });

            for (var i in players_info)
            {
                if (i<10)
                    CreateFriendPanel(players_info[i])
            }
        }
    })
}

function CreateFriendPanel(data) {
    var steamID64 = ConvertID64(data.steamID)
    var playerPanel = $.CreatePanel("Panel", friendsPanel, "Friend_"+steamID64)
    playerPanel.steamID = steamID64
    playerPanel.score = FormatScore(data.score)
    playerPanel.rank = data.rank
    playerPanel.percentile = FormatPercentile(data.percentile)
    playerPanel.BLoadLayout("file://{resources}/layout/custom_game/profile_friend.xml", false, false);
}

function ConvertID64 (steamID32) {
    return '765'+(parseInt(steamID32) + 61197960265728)
}

// Format score in k (thousands) format
function FormatScore(score) {
    return score.substring(0, score.length-3)+"k";
}

function FormatPercentile(percent) {
    if (percent=="0") percent="1" //Adjust while decimal point 0 isn't working
    return percent+"%"
}

function ToggleProfile() {
    $.Msg("Toggle")
    $("#MyProfile").ToggleClass("Hide")
}

(function () {
    $.Msg("Profile Loaded")
    GetPlayerFriends(Game.GetLocalPlayerID())
})();