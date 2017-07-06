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
    if (percent == 0 || parseFloat(percent) < 0.1)
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

// Handles versioning labels
GameUI.FormatVersion = function (version_string) {
    if (version_string == 'B230216') version_string = "0.8"
    else if (version_string == "B010316" || version_string == "B010316b") version_string = "0.9"

    return "v"+version_string
}

// Converts Seconds into a nice duration format
GameUI.FormatDuration = function(sec_num) {
    var hours   = Math.floor(sec_num / 3600);
    var minutes = Math.floor((sec_num - (hours * 3600)) / 60);
    var seconds = sec_num - (hours * 3600) - (minutes * 60);

    if (minutes < 10) {minutes = "0"+minutes;}
    if (seconds < 10) {seconds = "0"+seconds;}

    var time    = '';
    if (parseInt(hours) > 0) time = time+hours+':'
    time = time+minutes+":"+seconds

    return time;
}

// Converts difference between two dates in "Y-m-d H:i:s" format
//"current_time":"2016-03-30 12:53:43" - "date":"2016-03-27 04:52:54" = 3 days ago
// 1 minute ago // 5 minutes ago // 1 hour ago // 5 hours ago // 1 day ago // 5 days ago // 1 week ago // 2 weeks ago //1 month ago // 5 months ago // 1 year ago // 5 years ago
GameUI.FormatTimeAgo = function (time_now, time_old) {
    if (!time_now)
    {
        var d = new Date()
        time_now = d.getTime()
    }

    var now = new Date(time_now)
    var old = new Date(time_old)
    var diff = (now - old)/1000

    var years = DateDiff.inYears(old, now)
    if (years > 0)
        return DateDiff.inPlural(years, "year")

    var weeks = DateDiff.inWeeks(old, now)
    var months = DateDiff.inMonths(old, now)
    if (months > 0 && weeks > 3)
        return DateDiff.inPlural(months, "month")
    
    if (weeks > 0)
        return DateDiff.inPlural(weeks, "week")

    var days = DateDiff.inDays(old, now)
    var hours = DateDiff.inHours(old, now)
    
    if (days > 0 && hours > 23)
        return DateDiff.inPlural(days, "day")

    if (hours > 0)
        return DateDiff.inPlural(hours, "hour")

    var minutes = DateDiff.inMinutes(old, now)
    if (minutes > 0)
        return DateDiff.inPlural(minutes, "minute")
}

var DateDiff = {

    inMinutes: function(d1, d2) {
        var t2 = d2.getTime();
        var t1 = d1.getTime();

        return parseInt((t2-t1)/(60*1000));
    },

    inHours: function(d1, d2) {
        var t2 = d2.getTime();
        var t1 = d1.getTime();

        return parseInt((t2-t1)/(24*60*1000));
    },

    inDays: function(d1, d2) {
        var t2 = d2.getTime();
        var t1 = d1.getTime();

        return parseInt((t2-t1)/(24*3600*1000));
    },

    inWeeks: function(d1, d2) {
        var t2 = d2.getTime();
        var t1 = d1.getTime();

        return parseInt((t2-t1)/(24*3600*1000*7));
    },

    inMonths: function(d1, d2) {
        var d1Y = d1.getFullYear();
        var d2Y = d2.getFullYear();
        var d1M = d1.getMonth();
        var d2M = d2.getMonth();

        return (d2M+12*d2Y)-(d1M+12*d1Y);
    },

    inYears: function(d1, d2) {
        return d2.getFullYear()-d1.getFullYear();
    },

    // I have no idea what I'm doing
    inPlural: function(number, name) {
        var output = number + " " + name
        if (number > 1) output += "s"
        return $.Localize("#"+output) + " " + $.Localize("#ago")
    },
}

GameUI.SetTextSafe = function (panel, childName, textValue) {
    if ( panel === null )
        return;
    var childPanel = panel.FindChildInLayoutFile( childName )
    if ( childPanel === null )
        return;
    childPanel.text = textValue;
}

GameUI.SetClassForChildInLayout = function (className, childName, panel, condition) {
    if ( panel === null )
        return;
    var childPanel = panel.FindChildInLayoutFile( childName )
    if ( childPanel === null )
        return;
    if (childPanel)
        childPanel.SetHasClass(className, condition )
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
    if (GameUI.Ranks === undefined) return

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
    if (GameUI.Ranks === undefined) return
        
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

GameUI.CreateBadges = function (parent, version, rank_classic, percentile_classic, rank_express, percentile_express) {
    var panel = $.CreatePanel( "Panel", parent, "Profile_Badge_"+version);
    panel.BLoadLayout( "file://{resources}/layout/custom_game/profile_ranking.xml", false, false );

    GameUI.SetTextSafe( panel, "BadgeVersion", version); //Version is shared by both badges
    panel.FindChildInLayoutFile("BadgeClassic").SetHasClass( "Hide", rank_classic == 0)
    panel.FindChildInLayoutFile("BadgeExpress").SetHasClass( "Hide", rank_express == 0)

    if (rank_classic)
    {
        GameUI.SetTextSafe( panel, "BadgePercentile_Classic", GameUI.FormatPercentile(percentile_classic));
        GameUI.SetTextSafe( panel, "BadgeRank_Classic", "#" + GameUI.FormatRank(rank_classic));
        panel.FindChildInLayoutFile( "BadgeClassic" ).AddClass(GameUI.GetRankImage(rank_classic,percentile_classic)+"_percentile");
    }
    else
    {
        panel.FindChildInLayoutFile("BadgeClassic").style['width'] = "0%"
        panel.FindChildInLayoutFile("BadgeExpress").style['width'] = "100%"
        panel.style['width'] = "60px;"
    }

    if (rank_express)
    {
        GameUI.SetTextSafe( panel, "BadgePercentile_Express", GameUI.FormatPercentile(percentile_express));
        GameUI.SetTextSafe( panel, "BadgeRank_Express", "#" + GameUI.FormatRank(rank_express));
        panel.FindChildInLayoutFile( "BadgeExpress" ).AddClass(GameUI.GetRankImage(rank_express,percentile_express)+"_percentile");
    }
    else
    {
        panel.FindChildInLayoutFile("BadgeClassic").style['width'] = "100%"
        panel.FindChildInLayoutFile("BadgeExpress").style['width'] = "0%"
        panel.style['width'] = "60px;"
    }
}

GameUI.CommaFormat = function (value) {
    return value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

// Developer function to test unreleased stuff
var Developers = [76561198046984233,76561197968301566,76561198027264543,76561197995227322,76561198045264681,76561198019839522,76561197992246166,76561198084443997]
GameUI.IsDeveloper = function (steamID64) {
    return Developers.indexOf(Number(steamID64)) != -1
}

var Translators = [76561198047021815,76561198060578494,76561198017567489,76561198050765387]
GameUI.IsTranslator = function (steamID64) {
    return Translators.indexOf(Number(steamID64)) != -1
}

GameUI.DeveloperInGame = function() {
    for (var playerID in Game.GetAllPlayerIDs())
        if (GameUI.IsDeveloper(GameUI.GetPlayerSteamID(playerID)))
            return true
    return false
}

// Returns a reward level taken from rewards nettable
GameUI.RewardLevel = function (steamID64) {
    var playerReward = CustomNetTables.GetTableValue( "rewards", steamID64)
    if (GameUI.IsDeveloper(steamID64))
        return "Developer"
    else if (GameUI.IsTranslator(steamID64))
        return "Translator"
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
            if (rewardLevel == "Developer" || rewardLevel == "Translator")
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
    return Players.HasCustomGameTicketForPlayerID(parseInt(playerID)) || rewardLevel == "Developer" || rewardLevel == "Translator" || rewardLevel == rewardLevel > 0
}

// Save request by steamID
GameUI.CheckPlayerPass = function (steamID64, callback) {
    var steamID32 = GameUI.ConvertID32(steamID64)

    // Mark devs as pass owners in the UI
    var rewardLevel = GameUI.RewardLevel(steamID64)
    if (rewardLevel == "Developer" || rewardLevel == "Translator")
    {
        callback(true)
        return
    }

    $.AsyncWebRequest( "http://hatinacat.com/leaderboard/data_request.php?req=save&id="+steamID32, { type: 'GET', 
        success: function( data ) {
            var info = JSON.parse(data);
            if (info["save"])
            {
                callback(info["save"]["pass"] == 1)
            }
            else
                callback(false)
        },

        error: function() {
            callback(false)
        }
    })
}

GameUI.SetupAvatarTooltip = function (avatar, root, steamID64) {
    if (!avatar || !root || !steamID64)
    {
        $.Msg("Wrong panels received when trying to setup avatar tooltip for "+steamID64)
        return;
    }

    avatar.ClearPanelEvent("onmouseover")
    avatar.ClearPanelEvent("onmouseout")
    avatar.tooltip = undefined

    avatar.SetPanelEvent("onmouseover", function() {
        if (avatar.tooltip === undefined) {
            var panel = $.CreatePanel("Panel", root, "PlayerAvatarTooltip")
            panel.steamID64 = steamID64
            panel.BLoadLayout("file://{resources}/layout/custom_game/profile_avatar.xml", false, false);

            var pos = avatar.GetPositionWithinWindow()
            var relation = 1080 / root.actuallayoutheight;
            var posX = (pos.x+avatar.actuallayoutwidth)*relation
            var posY = pos.y*relation
            panel.style.x = posX + "px";
            panel.style.y = posY + "px";

            avatar.tooltip = panel
            panel.avatar = avatar

            GameUI.ApplyPanelBorder(panel, steamID64)
        }
        else
        {
            avatar.tooltip.steamID64 = steamID64
            avatar.tooltip.Show()
        }
    })

    avatar.SetPanelEvent("onmouseout", function() {
        avatar.tooltip.Hide()
    })
}

// Returns the SteamID 64bit of a player by ID
GameUI.GetPlayerSteamID = function (playerID) {
    var playerInfo = Game.GetPlayerInfo(parseInt(playerID))
    return playerInfo ? playerInfo.player_steamid : -1
}

// Local player steamID shortcut
GameUI.GetLocalPlayerSteamID = function () {
    var playerInfo = Game.GetPlayerInfo(Game.GetLocalPlayerID())
    return playerInfo ? playerInfo.player_steamid : -1
}

Game.IsCoop = function() {
    var mapInfo = Game.GetMapInfo()
    if (mapInfo)
        return mapInfo.map_display_name == "element_td_coop"
}

Game.IsExpress = function() {
    return CustomNetTables.GetTableValue("gameinfo", "length").value == "Express"
}

Game.IsShort = function() {
    return CustomNetTables.GetTableValue("gameinfo", "length").value == "Short"
}

Game.InterestStopped = function() {
    return (CustomNetTables.GetTableValue("gameinfo", "interest_stopped").value == 1)
}