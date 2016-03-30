"use strict";

var statsURL = 'http://hatinacat.com/leaderboard/data_request.php?req=stats&id='
var friendsURL = 'http://hatinacat.com/leaderboard/data_request.php?req=friends&id='
var Profile = $("#Profile")
var CustomBuilders = $("#CustomBuilders")
var Loading = $("#Loading")
var friendsPanel = $("#FriendsContainer")
var currentProfile;
var currentLB = 0;
var friendsRank
var friends = []

//cache everything
var Stats = {}
var FriendsOf = {}

function GetStats(steamID32) {
    ClearFields()

    if (Stats[steamID32])
    {
        $.Msg("Loading stats for "+steamID32)
        SetStats(Stats[steamID32])
        return
    }

    $.Msg("Getting stats data for "+steamID32+"...")
    $.AsyncWebRequest( statsURL+steamID32+"&raw=1", { type: 'GET', 
        success: function( data ) {
            var info = JSON.parse(data);
            var player_info = info["player"]

            var allTime = player_info["allTime"]
            if (allTime === undefined)
                return

            SetStats(player_info)
        }
    })
}

function SetStats(player_info)
{
    Stats[player_info["steamID"]] = player_info

    var allTime = player_info["allTime"]
    $("#GamesWon").text = allTime["gamesWon"]
    $("#BestScore").text = GameUI.FormatScore(allTime["bestScore"])

    // General
    $("#kills").text = GameUI.FormatNumber(allTime["kills"])
    $("#frogKills").text = GameUI.FormatNumber(allTime["frogKills"])
    $("#networth").text = GameUI.FormatGold(allTime["networth"])
    $("#interestGold").text = GameUI.FormatGold(allTime["interestGold"])
    $("#cleanWaves").text = GameUI.FormatNumber(allTime["cleanWaves"])
    $("#under30").text = GameUI.FormatNumber(allTime["under30"])

    // GameMode
    MakeBars(allTime, ["normal","hard","veryhard","insane"])
    MakeBoolBar(allTime, "order_chaos")
    MakeBoolBar(allTime, "horde_endless")
    MakeBoolBar(allTime, "express")

    var random = allTime["random"]
    var gamesPlayed = allTime["gamesPlayed"]
    $("#random").text = random+" ("+(random/gamesPlayed*100).toFixed(0)+"%)"
    $("#towersBuilt").text = GameUI.FormatNumber(Number(allTime["towers"]) + Number(allTime["towersSold"]))
    $("#towersSold").text = GameUI.FormatNumber(allTime["towersSold"])
    $("#lifeTowerKills").text = GameUI.FormatNumber(allTime["lifeTowerKills"])
    $("#goldTowerEarn").text = GameUI.FormatGold(allTime["goldTowerEarn"])

    // Towers
    var dual = MakeFirstDual(allTime["firstDual"])
    var triple = MakeFirstTriple(allTime["firstTriple"])

    // Element Usage
    var light = allTime["light"]
    var dark = allTime["dark"]
    var water = allTime["water"]
    var fire = allTime["fire"]
    var nature = allTime["nature"]
    var earth = allTime["earth"]
    var total_elem = light+dark+water+fire+nature+earth
    var favorite = allTime["favouriteElement"]

    var nextStart = 0
    nextStart = RadialStyle("light", nextStart, light/total_elem)
    nextStart = RadialStyle("dark", nextStart, dark/total_elem)
    nextStart = RadialStyle("water", nextStart, water/total_elem)
    nextStart = RadialStyle("fire", nextStart, fire/total_elem)
    nextStart = RadialStyle("nature", nextStart, nature/total_elem)
    nextStart = RadialStyle("earth", nextStart, earth/total_elem)

    // Milestones
    var milestones = player_info["milestones"]
    if (milestones === undefined)
        return

    // Build reverse array, newer ranks first
    var milestones_array = [];
    for (version in milestones) {
       milestones_array.unshift(version);
    }

    // Limit to 1 row
    var badgesCreated = 0
    var badgeLimit = 8

    for (var i in milestones_array) {
        var version = milestones_array[i]
        var rank_classic = milestones[version]["normal_rank"]
        var rank_express = milestones[version]["express_rank"]

        // Classic+Express
        if (rank_classic != false && rank_express != false)
        {
            if (badgesCreated+2 > badgeLimit)
                break

            badgesCreated+=2
            var percentile_classic = rank_classic / milestones[version]["normal_count"] * 100
            var percentile_express = rank_express / milestones[version]["express_count"] * 100
            CreateProfileBadges(GameUI.FormatVersion(version), rank_classic, percentile_classic, rank_express, percentile_express)
        }

        // Only Classic
        else if (rank_classic != false)
        {
            if (badgesCreated+1 > badgeLimit)
                break

            badgesCreated++
            var percentile_classic = rank_classic / milestones[version]["normal_count"] * 100
            CreateProfileBadges(GameUI.FormatVersion(version), rank_classic, percentile_classic, 0, 0)
        }

        // Only Express
        else if (rank_express != false)
        {
            if (badgesCreated+1 > badgeLimit)
                break

            badgesCreated++
            var percentile_express = rank_express / milestones[version]["express_count"] * 100
            CreateProfileBadges(GameUI.FormatVersion(version), 0, 0, rank_express, percentile_express)
        }
    };

    $("#ClassicRank").text = (player_info["rank"] === undefined) ? "--" : GameUI.FormatRank(player_info["rank"]);
    $("#ExpressRank").text = (player_info["rank_exp"] === undefined) ? "--" : GameUI.FormatRank(player_info["rank_exp"]);
    $("#FrogsRank").text = (player_info["rank_frogs"] === undefined) ? "--" : GameUI.FormatRank(player_info["rank_frogs"]);

    // Matches
    var rawInfo = player_info["raw"]
    for (var i in rawInfo)
    {
        var match = rawInfo[i]
        if (match['cleared'] != 0)
        {
            CreateMatch(rawInfo[i])
        }
    }
}

var elementNames = ["light", "dark", "water", "fire", "nature", "earth"]
function CreateMatch(info) {
    var matchID = info['matchID']
    var version = info['version']

    var panel = $.CreatePanel( "Panel", $("#MatchesContainer"), "Match_"+matchID);
    panel.BLoadLayout( "file://{resources}/layout/custom_game/profile_match.xml", false, false );

    // Modes
    var difficulty = info["difficulty"]
    var diff = "-";
    if (difficulty == "Normal")
        diff = "N";
    else if (difficulty == "Hard")
        diff = "H";
    else if (difficulty == "VeryHard")
        diff = "VH";
    else if (difficulty == "Insane")
        diff = "I";

    var diffPanel = panel.FindChildInLayoutFile( "Difficulty" );
    if ( diffPanel )
    {
        diffPanel.text = diff
        diffPanel.SetHasClass( "Normal", diff == "N");
        diffPanel.SetHasClass( "Hard", diff == "H");
        diffPanel.SetHasClass( "VeryHard", diff == "VH");
        diffPanel.SetHasClass( "Insane", diff == "I");
    }

    // Hide any default game mode choices
    GameUI.SetClassForChildInLayout("Hide", "Express", panel, ! info["mode"] == "1")
    GameUI.SetClassForChildInLayout("Hide", "Chaos", panel, info["order"] == "Normal")
    GameUI.SetClassForChildInLayout("Hide", "Rush", panel, info["horde"] == "Normal")
    GameUI.SetClassForChildInLayout("Hide", "Random", panel, info["random"] == "AllPick")

    // Time
    //"date":"2016-03-27 04:52:54","time_start":"03/26/16 14:49:04","time_end":"03/26/16 14:52:23"
    GameUI.SetTextSafe(panel, "MatchTime", GameUI.FormatDuration(info["duration"]))

    // Score
    GameUI.SetTextSafe(panel, "MatchScore", GameUI.FormatScore(info['score']))

    // Elements
    for (var i in elementNames)
    {
        var elem = elementNames[i]
        var level = info[elem]
        var elementPanel = panel.FindChildTraverse( elem )
        if (elementPanel !== null)
        {
            if (level==0)
                elementPanel.AddClass("Hide")
            else
            {
                elementPanel.RemoveClass("Hide")
                var elem_level = panel.FindChildTraverse( elem+"_level" )
                if (elem_level !== null)
                {
                    elem_level.text = level
                }
            }
        }
    }
}

function CreateProfileBadges(version, rank_classic, percentile_classic, rank_express, percentile_express) {
    var panel = $.CreatePanel( "Panel", $("#MilestonesContainer"), "Profile_Badge_"+version);
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

function ClearFields() {
    $("#GamesWon").text = "-"
    $("#BestScore").text = "-"

    // General
    $("#kills").text = "-"
    $("#frogKills").text = "-"
    $("#networth").text = "-"
    $("#interestGold").text = "-"
    $("#cleanWaves").text = "-"
    $("#under30").text = "-"

    // GameMode
    var data = []
    data["gamesPlayed"] = 4
    data["normal"] = 1
    data["hard"] = 1
    data["veryhard"] = 1
    data["insane"] = 1
    data["order_chaos"] = 0
    data["horde_endless"] = 0
    data["express"] = 0

    MakeBars(data, ["normal","hard","veryhard","insane"])
    MakeBoolBar(data, "order_chaos")
    MakeBoolBar(data, "horde_endless")
    MakeBoolBar(data, "express")

    var random = "-"
    $("#gamesPlayed").text = 0
    $("#random").text = "-"
    $("#towersBuilt").text = "-"
    $("#towersSold").text = "-"
    $("#lifeTowerKills").text = "-"
    $("#goldTowerEarn").text = "-"

    // Towers
    MakeFirstDual("")
    MakeFirstTriple("")

    // Element Usage
    var light = 1
    var dark = 1
    var water = 1
    var fire = 1
    var nature = 1
    var earth = 1
    var total_elem = light+dark+water+fire+nature+earth
    var favorite = "-"

    var nextStart = 0
    nextStart = RadialStyle("light", nextStart, light/total_elem)
    nextStart = RadialStyle("dark", nextStart, dark/total_elem)
    nextStart = RadialStyle("water", nextStart, water/total_elem)
    nextStart = RadialStyle("fire", nextStart, fire/total_elem)
    nextStart = RadialStyle("nature", nextStart, nature/total_elem)
    nextStart = RadialStyle("earth", nextStart, earth/total_elem)

    $("#ClassicRank").text = "--"
    $("#ExpressRank").text = "--"
    $("#FrogsRank").text = "--"

    // Milestones
    var childCount = $("#MilestonesContainer").GetChildCount()
    for (var i = 0; i < childCount; i++) {
        var child = $("#MilestonesContainer").GetChild(i)
        if (child) child.DeleteAsync(0)
    };

    // Matches
    var childCount = $("#MatchesContainer").GetChildCount()
    for (var i = 0; i < childCount; i++) {
        var child = $("#MatchesContainer").GetChild(i)
        if (child) child.DeleteAsync(0)
    };
}

function GetPlayerFriends(steamID32, leaderboard_type) {
    friendsRank = 0
    currentProfile = steamID32

    for (var i = 0; i < friends.length; i++) {
        friends[i].DeleteAsync(0)
    };
    friends = []

    if (FriendsOf[steamID32] && FriendsOf[steamID32][leaderboard_type])
    {
        $.Msg("Loading player friends for "+steamID32)
        SetPlayerFriends(FriendsOf[steamID32][leaderboard_type], steamID32, leaderboard_type, false)
        return
    }

    $.Msg("Getting friends data for "+steamID32+"...")
    Loading.RemoveClass( "Hide" )
    $.AsyncWebRequest( friendsURL+steamID32+"&lb="+leaderboard_type, { type: 'GET', 
        success: function( data ) {
            var info = JSON.parse(data);

            if (FriendsOf[steamID32] === undefined)
                FriendsOf[steamID32] = {}

            SetPlayerFriends(info, steamID32, leaderboard_type, true)
        }
    })
}

function SetPlayerFriends(info, steamID32, leaderboard_type, addSelf) {
    FriendsOf[steamID32][leaderboard_type] = info

    var delay = 0
    var delay_per_panel = 0.1
    var players_info = info["players"]
            
    Loading.AddClass( "Hide" )

    if (!players_info){
        $("#PrivateProfile").RemoveClass( "Hide" )
        return
    }
    $("#PrivateProfile").AddClass( "Hide" )

    // Only need to add self once, on the first request
    if (addSelf)
    {
        var self_player_rank = info["self"]
        if (self_player_rank)
            players_info.push(self_player_rank)
    }

    // Sort by rank
    players_info.sort(function(a, b) {
        return parseInt(a.rank) - parseInt(b.rank);
    });

    for (var i in players_info)
    {
        var callback = function( data )
        {
            return function(){ 
                if (currentProfile == steamID32 && currentLB == leaderboard_type)
                    CreateFriendPanel(data, leaderboard_type)
            }
        }( players_info[i] );

        $.Schedule( delay, callback )
        delay += delay_per_panel;
    }
}

function CreateFriendPanel(data, leaderboard_type) {
    friendsRank++

    var steamID64 = GameUI.ConvertID64(data.steamID)
    var playerPanel = $.CreatePanel("Panel", friendsPanel, "Friend_"+steamID64)
    playerPanel.steamID = steamID64
    playerPanel.score = leaderboard_type == 2 ? data.frogs : GameUI.FormatScore(data.score)
    playerPanel.friendRank = friendsRank
    playerPanel.rank = GameUI.FormatRank(data.rank)
    playerPanel.percentile = GameUI.FormatPercentile(data.percentile)
    playerPanel.BLoadLayout("file://{resources}/layout/custom_game/profile_friend.xml", false, false);

    playerPanel.SetPanelEvent( "onactivate", function(){ LoadProfile(steamID64) })
    friends.push(playerPanel)

    var steamID = GameUI.GetLocalPlayerSteamID()
    if (steamID64 == steamID)
        playerPanel.AddClass("local")
}

function LoadProfile(steamID64) {
    $.Msg("Loading profile of player "+steamID64)

    $("#AvatarImageProfile").steamid = steamID64
    $("#UserNameProfile").steamid = steamID64

    var isSelfProfile = steamID64 == GameUI.GetLocalPlayerSteamID()
    $("#ProfileBackContainer").SetHasClass("Hide", isSelfProfile)
    $("#UserNameProfile").SetHasClass("selfName", isSelfProfile)
    $("#UserNameProfile").SetHasClass("friendName", !isSelfProfile)

    currentProfile = GameUI.ConvertID32(steamID64)
    GetStats(currentProfile)
    ShowFriendRanks("classic", true)
}

function ToggleProfile() {
    Profile.ToggleClass("Hide")

    // Load self in the background
    if (Profile.BHasClass( "Hide" ))
    {
        Game.EmitSound("ui_quit_menu_fadeout")
        LoadLocalProfile()
    }
    else
        Game.EmitSound("ui_goto_player_page")

    CloseCustomBuilders()
}

function CloseProfile() {
    Profile.SetHasClass( "Hide", true )
}
function CloseCustomBuilders(argument) {
    CustomBuilders.SetHasClass( "Hide", true )
}

function ToggleCustomBuilders() {
    Game.EmitSound("ui_generic_button_click")
    CustomBuilders.ToggleClass("Hide")
    CloseProfile()
}

var LB_types = ["classic","express","frogs"]
function ShowFriendRanks(leaderboard_type, force) {
    for (var i = 0; i < LB_types.length; i++) {
        var name = LB_types[i]
        var panel = $("#"+name+"_radio")
        panel.SetHasClass( "ActiveTab", LB_types[i] == leaderboard_type )
    };

    if (!force)
        Game.EmitSound("ui_rollover_micro")

    currentLB = LB_types.indexOf(leaderboard_type)
    GetPlayerFriends(currentProfile, currentLB)
}

var leftNames = ["stats","matches","achievements"]
function ShowProfileTab ( tabName ) {
    // Swap radio buttons and panel visibility
    for (var i = 0; i < leftNames.length; i++) {
        var name = leftNames[i]

        var radio = $("#"+name+"_radio")
        if (radio)
            radio.SetHasClass( "ActiveTab", name == tabName )

        var tabPanel = $("#"+name+"_Tab")
        if (tabPanel)
            tabPanel.SetHasClass( "Hide", name != tabName )
    };

    Game.EmitSound("ui_rollover_micro")
}

function MakeButtonVisible() {
    var bShowProfile = GameUI.PlayerHasProfile(Game.GetLocalPlayerID())
    $("#ProfileToggleContainer").SetHasClass("Hide", !bShowProfile)
}

function LoadLocalProfile() {
    var steamID64 = GameUI.GetLocalPlayerSteamID()
    LoadProfile(steamID64)

    $("#AvatarImageMini").steamid = steamID64

    //Testing
    //ToggleProfile()
    //ShowProfileTab('achievements')
}

(function () {
    $.Schedule(0.1, function()
    {
        if (Players.HasCustomGameTicketForPlayerID(Game.GetLocalPlayerID()) || GameUI.RewardLevel(GameUI.GetLocalPlayerSteamID()) == "Developer")
        {
            MakeButtonVisible()
            LoadLocalProfile()
            GameUI.AcceptWheel()
        }
    })
})();