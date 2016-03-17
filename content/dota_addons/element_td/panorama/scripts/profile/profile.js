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
    var steamID64 = GameUI.ConvertID64(data.steamID)
    var playerPanel = $.CreatePanel("Panel", friendsPanel, "Friend_"+steamID64)
    playerPanel.steamID = steamID64
    playerPanel.score = GameUI.FormatScore(data.score)
    playerPanel.rank = data.rank
    playerPanel.percentile = GameUI.FormatPercentile(data.percentile)
    playerPanel.BLoadLayout("file://{resources}/layout/custom_game/profile_friend.xml", false, false);
}

function ToggleProfile() {
    $.Msg("Toggle")
    $("#MyProfile").ToggleClass("Hide")
}

(function () {
    $.Msg("Profile Loaded")
    GetPlayerFriends(Game.GetLocalPlayerID())
})();