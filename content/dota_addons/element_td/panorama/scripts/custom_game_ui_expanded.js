/* 
    This contains scripts to reutilize through various interface files
    The file doesn't need to be included, as the functions are accessible in global GameUI scope
*/

// Converts a steamID32 into 64 bit version to use in DOTAAvatarImage/DOTAUserName
GameUI.ConvertID64 = function (steamID32) {
    return '765'+(parseInt(steamID32) + 61197960265728)
}

// Returns rank normalized for numbers over a thousand
GameUI.FormatRank = function (rank) {
    var fixed = 1;
    if (rank > 9999)
        fixed = 0;
    return rank > 999 ? +(rank/1000).toFixed(fixed) + 'k' : rank;
}

// Returns score in k (thousands) format
GameUI.FormatScore =  function (score) {
    return score.substring(0, score.length-3)+"k";
}

// Returns percentile in % format with 1 decimal point
GameUI.FormatPercentile = function (percent) {
    return +percent.toFixed(1) + "%"
}

// Developer function to test unreleased stuff
var Developers = [76561198046984233,76561197968301566,76561198027264543,76561197995227322,76561198045264681,76561198008120955]
GameUI.IsDeveloper = function (steamID64) {
    return Developers.indexOf(Number(steamID64)) != -1
}

// Returns a reward level taken from rewards nettable
GameUI.RewardLevel = function (steamID64) {
    var playerReward = CustomNetTables.GetTableValue( "rewards", steamID64)
    if (GameUI.IsDeveloper(steamID64))
        return "Developer"
    else if (playerReward)
        return playerReward.tier
    else
        return 0
}

// Applies style to avatar profiles
GameUI.ApplyPanelBorder = function (panel, steamID64){
    var rewardLevel = GameUI.RewardLevel(steamID64)

    if (rewardLevel != 0)
    {
        var border = panel.FindChildInLayoutFile( "BorderImage" );
        if (border !== undefined && border !== null)
        {
            border.RemoveClass( "HiddenBorder" )
            if (rewardLevel == "Developer")
                border.AddClass( "EpicBorder" )

            else if (rewardLevel >= 2)
                border.AddClass( "GoldBorder" )
        }
    }
}
