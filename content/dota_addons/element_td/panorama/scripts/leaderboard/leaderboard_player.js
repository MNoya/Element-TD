var Root = $.GetContextPanel()

function SetupPlayerEntry () {
    //$.Msg("SteamID:",Root.steamID)
    $("#PlayerRank").text = Root.rank;
    $("#AvatarImage").steamid = Root.steamID;
    $("#PlayerName").steamid = Root.steamID;
    $("#PlayerScore").text = Root.score;
    if (Root.id.indexOf("FrogsLeaderboard") != -1)
        $("#PlayerScore").text = Root.frogs;
}

(function () {
    SetupPlayerEntry()
})();