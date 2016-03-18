var Root = $.GetContextPanel()

function SetupFriendEntry () {
    //$.Msg("SteamID:",Root.steamID)
    $("#FriendRank").text = Root.friendRank
    $("#AvatarImageFriend").steamid = Root.steamID;
    $("#FriendName").steamid = Root.steamID;
    $("#FriendScore").text = Root.score;
    $("#FriendGlobalRank").text = Root.rank;
}

(function () {
    SetupFriendEntry()
})();