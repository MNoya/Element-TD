var Root = $.GetContextPanel()

function SetupFriendEntry () {
    //$.Msg("SteamID:",Root.steamID)
    $("#FriendRank").text = Root.rank;
    $("#AvatarImageFriend").steamid = Root.steamID;
    $("#FriendName").steamid = Root.steamID;
    $("#FriendScore").text = Root.score;
    $("#FriendPercentile").text = Root.percentile;
}

(function () {
    SetupFriendEntry()
})();