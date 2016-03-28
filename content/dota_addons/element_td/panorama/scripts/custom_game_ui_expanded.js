/* 
    This contains scripts to reutilize through various interface files
    The file doesn't need to be included, as the functions are accessible in global GameUI scope
*/

// Converts a steamID32 into 64 bit version to use in DOTAAvatarImage/DOTAUserName
GameUI.ConvertID64 = function (steamID32) {
    return '765'+(parseInt(steamID32) + 61197960265728)
}

// Converts a steamID64 into 32 bit version
GameUI.ConvertID32 = function (steamID64) {
    return steamID64.slice(3) - 61197960265728;
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
    if (score.length > 3)
        return GameUI.CommaFormat(score.substring(0, score.length-3))+"k";
    else
        return score
}

// Returns percentile in % format with 1 decimal point
GameUI.FormatPercentile = function (percent) {
    if (percent == 0)
        return "0.1%" //anthony please forgive me
    else
        return +percent.toFixed(1) + "%"
}

// Returns gold with commas and k
GameUI.FormatGold = function (gold) {
    if (gold.toString().length <= 4)
        return GameUI.CommaFormat(gold)
    else
    {
        var formatted = GameUI.CommaFormat(gold)
        return formatted.substring(0, formatted.length-4)+"k";
    }
}

// Returns a number with thousands comma sepeartion and if the number is bigger than 6 digits it will include a k
GameUI.FormatNumber = function (num) {
    if (num.toString().length <= 6)
        return GameUI.CommaFormat(num)

    else
    {
        var formatted = GameUI.CommaFormat(num)
        return formatted.substring(0, formatted.length-4)+"k";
    }
}

GameUI.SetTextSafe = function ( panel, childName, textValue ) {
    if ( panel === null )
        return;
    var childPanel = panel.FindChildInLayoutFile( childName )
    if ( childPanel === null )
        return;
    childPanel.text = textValue;
}

GameUI.CreatePlayerRank = function(parent, percentile, rank, playerID) {
    var id = "Player_" + playerID + "_Rank"
    var panel = $.CreatePanel( "Panel", parent, id);
    panel.BLoadLayout( "file://{resources}/layout/custom_game/ranking_player.xml", false, false );
    GameUI.SetTextSafe( panel, "RankingPercentile", GameUI.FormatPercentile(percentile));
    GameUI.SetTextSafe( panel, "RankingRank", "#" + GameUI.FormatRank(rank));
    panel.FindChildInLayoutFile( "RankingPlayer" ).AddClass(GameUI.GetRankImage(rank,percentile)+"_percentile");

    // Store it
    GameUI.Ranks[playerID] = panel
}

GameUI.ShowPlayerRank = function(playerID) {
    var panel = GameUI.Ranks[playerID]
    if (panel)
    {
        var rank = panel.FindChildInLayoutFile( "RankingPlayer" );
        if (rank)
        {
            rank.RemoveClass("slideOut");
            rank.RemoveClass("hidden");
        }
    }
}

GameUI.HidePlayerRank = function(playerID) {
    var panel = GameUI.Ranks[playerID]
    if (panel)
    {
        var rank = panel.FindChildInLayoutFile( "RankingPlayer" );
        if (rank)
        {
            rank.AddClass("slideOut");
            rank.AddClass("hidden");
        }
    }
}

GameUI.GetRankImage = function ( rank, percentile ) {
    if (percentile <= 20)
        return "0";
    else if (percentile <= 40)
        return "20";
    else if (percentile <= 60)
        return "40";
    else if (percentile <= 80)
        return "60";
    else
        return "80";
}

GameUI.CommaFormat = function (value) {
    return value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
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
GameUI.ApplyPanelBorder = function (panel, steamID64) {
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

GameUI.DenyWheel = function() {
    GameUI.AcceptWheeling = 0;
}

GameUI.AcceptWheel = function() {
    GameUI.AcceptWheeling = 1;
}

// Player Profile unlock
GameUI.PlayerHasProfile = function (playerID) {
    var steamID64 = GameUI.GetPlayerSteamID(playerID)
    var rewardLevel = GameUI.RewardLevel(steamID64)
    return rewardLevel == "Developer" || rewardLevel > 0
}

// Returns the SteamID 64bit of a player by ID
GameUI.GetPlayerSteamID = function (playerID) {
    var playerInfo = Game.GetPlayerInfo(playerID)
    return playerInfo ? playerInfo.player_steamid : -1
}

// Local player steamID shortcut
GameUI.GetLocalPlayerSteamID = function () {
    var playerInfo = Game.GetPlayerInfo(Game.GetLocalPlayerID())
    return playerInfo ? playerInfo.player_steamid : -1
}

