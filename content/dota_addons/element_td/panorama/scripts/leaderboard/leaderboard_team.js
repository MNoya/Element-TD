var Root = $.GetContextPanel()

function SetupTeamEntry () {
    $("#TeamRank").text = Root.rank;

    for (var i = 1; i <= 4; i++) {
        if (Root.players[i])
            $("#AvatarImage"+i).steamid = Root.players[i];
        else
            $("#AvatarImage"+i).AddClass("Hide");
    };
    
    $("#TeamScore").text = Root.score;
    $("#TeamWave").text = Root.wave;
}

(function () {
    SetupTeamEntry()
})();