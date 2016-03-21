var Root = $.GetContextPanel()

function SetupFriendEntry () {
    //$.Msg("SteamID:",Root.steamID)
    $("#FriendRank").text = Root.friendRank
    $("#AvatarImageFriend").steamid = Root.steamID;
    $("#FriendName").steamid = Root.steamID;
    $("#FriendScore").text = Root.score;
    $("#FriendGlobalRank").text = Root.rank;
    $("#FriendPercentile").text = Root.percentile;

    $("#AvatarImageFriend").ClearPanelEvent( "onactivate" )
    $("#FriendName").ClearPanelEvent( "onactivate" )
}

(function () {
    SetupFriendEntry()
})();