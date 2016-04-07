"use strict";

var statsURL = 'http://hatinacat.com/leaderboard/data_request.php?req=stats&id='
var friendsURL = 'http://hatinacat.com/leaderboard/data_request.php?req=friends&id='
var dummyProfile = "76561198077142019" //Our Element TD dummy account
var Profile = $("#Profile")
var CustomBuilders = $("#CustomBuilders")
var Loading = $("#Loading")
var friendsPanel = $("#FriendsContainer")
var ResetButton = $("#ResetBuilderButton")
var PreviewMenu = $("#PreviewMenu")
var currentProfile;
var currentLB = 0;
var friendsRank
var friends = []
var bHasPass = GameUI.PlayerHasProfile(Game.GetLocalPlayerID())

//cache everything
var Stats = {}
var FriendsOf = {}
var currentTime

function GetStats(steamID32) {
    ClearFields()

    if (Stats[steamID32])
    {
        $.Msg("Setting existing stats for "+steamID32)
        SetStats(Stats[steamID32])
        return
    }

    $.Msg("Requesting stats data for "+steamID32+"...")
    $.AsyncWebRequest( statsURL+steamID32+"&raw=1", { type: 'GET', 
        success: function( data ) {
            var info = JSON.parse(data);
            var player_info = info["player"]

            if (player_info)
            {
                var allTime = player_info["allTime"]
                currentTime = player_info["current_time"]
                if (allTime)
                {
                    SetStats(player_info)
                    return
                }
            }

            $("#ErrorNoMatches").RemoveClass("Hide")
            $("#ErrorNoMilestones").RemoveClass("Hide")
        },

        error: function() {
            $("#ErrorNoMatches").RemoveClass("Hide")
            $("#ErrorNoMilestones").RemoveClass("Hide")
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
    $("#random_pick").text = random+" ("+(random/gamesPlayed*100).toFixed(0)+"%)"
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
    $("#ErrorNoMilestones").SetHasClass("Hide", milestones === undefined)
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
            GameUI.CreateBadges($("#MilestonesContainer"), GameUI.FormatVersion(version), rank_classic, percentile_classic, rank_express, percentile_express)
        }

        // Only Classic
        else if (rank_classic != false)
        {
            if (badgesCreated+1 > badgeLimit)
                break

            badgesCreated++
            var percentile_classic = rank_classic / milestones[version]["normal_count"] * 100
            GameUI.CreateBadges($("#MilestonesContainer"), GameUI.FormatVersion(version), rank_classic, percentile_classic, 0, 0)
        }

        // Only Express
        else if (rank_express != false)
        {
            if (badgesCreated+1 > badgeLimit)
                break

            badgesCreated++
            var percentile_express = rank_express / milestones[version]["express_count"] * 100
            GameUI.CreateBadges($("#MilestonesContainer"), GameUI.FormatVersion(version), 0, 0, rank_express, percentile_express)
        }
    };

    $("#ErrorNoMilestones").SetHasClass("Hide", badgesCreated > 0)

    $("#ClassicRank").text = (player_info["rank"] === undefined) ? "--" : GameUI.FormatRank(player_info["rank"]);
    $("#ExpressRank").text = (player_info["rank_exp"] === undefined) ? "--" : GameUI.FormatRank(player_info["rank_exp"]);
    $("#FrogsRank").text = (player_info["rank_frogs"] === undefined) ? "--" : GameUI.FormatRank(player_info["rank_frogs"]);

    // Matches
    var matchesCreated = 0
    var rawInfo = player_info["raw"]
    for (var i in rawInfo)
    {
        var match = rawInfo[i]
        if (match['cleared'] != 0)
        {
            matchesCreated++
            CreateMatch(rawInfo[i])
        }
    }
    $("#ErrorNoMatches").SetHasClass("Hide", matchesCreated > 0)
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

    // X Time ago
    GameUI.SetTextSafe(panel, "MatchTime", GameUI.FormatTimeAgo(currentTime, info["date"]))

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

function GetPlayerFriends(steamID32, leaderboard_type) {
    friendsRank = 0
    currentProfile = steamID32

    for (var i = 0; i < friends.length; i++) {
        friends[i].DeleteAsync(0)
    };
    friends = []

    if (FriendsOf[steamID32] && FriendsOf[steamID32][leaderboard_type])
    {
        $.Msg("Setting existing player friends for "+steamID32)
        SetPlayerFriends(FriendsOf[steamID32][leaderboard_type], steamID32, leaderboard_type, false)
        return
    }

    $.Msg("Requesting friends data for "+steamID32+"...")
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

    if (bHasPass)
        playerPanel.SetPanelEvent( "onactivate", function(){ LoadProfile(steamID64) })

    friends.push(playerPanel)

    var steamID = GameUI.GetLocalPlayerSteamID()
    if (steamID64 == steamID)
        playerPanel.AddClass("local")

    GameUI.SetupAvatarTooltip(playerPanel.FindChildInLayoutFile("AvatarImageFriend"), $.GetContextPanel(), steamID64)
}

function LoadProfile(steamID64) {
    $.Msg("Loading profile of player "+steamID64)

    $("#AvatarImageProfile").steamid = steamID64
    $("#UserNameProfile").steamid = steamID64

    GameUI.SetupAvatarTooltip($("#AvatarImageProfile"), $.GetContextPanel(), steamID64)    

    var isSelfProfile = steamID64 == GameUI.GetLocalPlayerSteamID()
    $("#ProfileBackContainer").SetHasClass("Hide", isSelfProfile)
    $("#UserNameProfile").SetHasClass("selfName", isSelfProfile)
    $("#UserNameProfile").SetHasClass("friendName", !isSelfProfile)

    currentProfile = GameUI.ConvertID32(steamID64)
    GetStats(currentProfile)
    ShowFriendRanks("classic")
}

// RandomGameUI.FormatNumber( data)
function SetPreviewProfile() {
    $.Msg("Setting Preview Profile")

    currentProfile = GameUI.ConvertID32(dummyProfile)
    $("#AvatarImageProfile").steamid = dummyProfile
    $("#UserNameProfile").steamid = dummyProfile

    $("#ProfileBackContainer").SetHasClass("Hide", true)
    $("#UserNameProfile").SetHasClass("selfName", true)
    $("#UserNameProfile").SetHasClass("friendName", false)

    $("#GamesWon").text = "-"
    $("#BestScore").text = "-"

    // General
    $("#kills").text = GameUI.FormatNumber("1337")
    $("#frogKills").text = GameUI.FormatNumber("4200000")
    $("#networth").text = GameUI.FormatGold("9999999")
    $("#interestGold").text = GameUI.FormatGold("322000")
    $("#cleanWaves").text = GameUI.FormatNumber("4200")
    $("#under30").text = GameUI.FormatNumber("3000")

    // GameMode
    var data = []
    data["gamesPlayed"] = 110
    data["normal"] = 50
    data["hard"] = 30
    data["veryhard"] = 10
    data["insane"] = 20
    data["order_chaos"] = 15
    data["horde_endless"] = 45
    data["express"] = 20

    MakeBars(data, ["normal","hard","veryhard","insane"])
    MakeBoolBar(data, "order_chaos")
    MakeBoolBar(data, "horde_endless")
    MakeBoolBar(data, "express")

    var random = RandomInt(30, 50)
    $("#gamesPlayed").text = GameUI.FormatNumber(data["gamesPlayed"])
    $("#random_pick").text = random+" ("+(random/data["gamesPlayed"]*100).toFixed(0)+"%)"
    $("#towersBuilt").text = GameUI.FormatNumber("1000")
    $("#towersSold").text = GameUI.FormatNumber("100")
    $("#lifeTowerKills").text = GameUI.FormatNumber("5000")
    $("#goldTowerEarn").text = GameUI.FormatGold("9999999")

    // Towers
    MakeFirstDual(pickRandomProperty(duals))
    MakeFirstTriple(pickRandomProperty(triples))

    // Element Usage
    var light = RandomInt(50, 100)
    var dark = RandomInt(50, 100)
    var water = RandomInt(50, 100)
    var fire = RandomInt(50, 100)
    var nature = RandomInt(50, 100)
    var earth = RandomInt(50, 100)
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
    GameUI.CreateBadges($("#MilestonesContainer"), GameUI.FormatVersion("1.4"), 1, 1, 0, 0)
    GameUI.CreateBadges($("#MilestonesContainer"), GameUI.FormatVersion("1.3"), 0, 0, 5, 5)
    GameUI.CreateBadges($("#MilestonesContainer"), GameUI.FormatVersion("1.2"), 10, 25, 0, 0)
    GameUI.CreateBadges($("#MilestonesContainer"), GameUI.FormatVersion("1.1"), 0, 0, 20, 45)
    GameUI.CreateBadges($("#MilestonesContainer"), GameUI.FormatVersion("1.0"), 4503, 85, 0, 0)

    // Matches
    CreateMatch({"matchID":1,"score":"420000","difficulty":"Insane","mode":0,"order":"1","horde":"1","random":"AllRandom","fire":"3","water":"2","nature":"3","earth":"0","light":"3","dark":"0","date":"2016-04-07 00:00:00"})
    CreateMatch({"matchID":1,"score":"300000","difficulty":"Insane","mode":0,"order":"Normal","horde":"1","random":"AllPick","fire":"3","water":"2","nature":"3","earth":"0","light":"2","dark":"1","date":"2016-04-06 00:00:00"})
    CreateMatch({"matchID":1,"score":"100000","difficulty":"Insane","mode":1,"order":"Normal","horde":"Normal","random":"AllRandom","fire":"3","water":"0","nature":"3","earth":"3","light":"0","dark":"3","date":"2016-04-01 00:00:00"})
    CreateMatch({"matchID":1,"score":"990000","difficulty":"VeryHard","mode":0,"order":"Normal","horde":"1","random":"AllPick","fire":"3","water":"2","nature":"3","earth":"0","light":"0","dark":"3","date":"2016-03-31 00:00:00"})
    CreateMatch({"matchID":1,"score":"10500","difficulty":"VeryHard","mode":1,"order":"1","horde":"Normal","random":"AllPick","fire":"3","water":"0","nature":"3","earth":"2","light":"3","dark":"0","date":"2016-03-30 00:00:00"})
    CreateMatch({"matchID":1,"score":"205000","difficulty":"Hard","mode":1,"order":"Normal","horde":"Normal","random":"AllPick","fire":"0","water":"0","nature":"3","earth":"2","light":"3","dark":"0","date":"2016-03-30 00:00:00"})
    CreateMatch({"matchID":1,"score":"215000","difficulty":"Hard","mode":0,"order":"1","horde":"1","random":"AllRandom","fire":"3","water":"2","nature":"3","earth":"0","light":"0","dark":"3","date":"2016-03-27 00:00:00"})
    CreateMatch({"matchID":1,"score":"100000","difficulty":"Hard","mode":0,"order":"1","horde":"Normal","random":"AllPick","fire":"3","water":"2","nature":"3","earth":"0","light":"3","dark":"0","date":"2016-03-24 00:00:00"})
    CreateMatch({"matchID":1,"score":"10550","difficulty":"Normal","mode":1,"order":"Normal","horde":"Normal","random":"AllRandom","fire":"0","water":"2","nature":"3","earth":"3","light":"3","dark":"0","date":"2016-03-22 00:00:00"})
    CreateMatch({"matchID":1,"score":"205000","difficulty":"Hard","mode":1,"order":"Normal","horde":"Normal","random":"AllPick","fire":"0","water":"2","nature":"3","earth":"0","light":"0","dark":"3","date":"2016-03-18 00:00:00"})
    CreateMatch({"matchID":1,"score":"215000","difficulty":"Hard","mode":0,"order":"1","horde":"1","random":"AllRandom","fire":"0","water":"0","nature":"3","earth":"2","light":"0","dark":"2","date":"2016-03-17 00:00:00"})
    CreateMatch({"matchID":1,"score":"100000","difficulty":"Hard","mode":0,"order":"1","horde":"Normal","random":"AllPick","fire":"3","water":"2","nature":"3","earth":"0","light":"3","dark":"0","date":"2016-03-15 00:00:00"})
    CreateMatch({"matchID":1,"score":"10550","difficulty":"Normal","mode":1,"order":"Normal","horde":"Normal","random":"AllRandom","fire":"3","water":"2","nature":"3","earth":"0","light":"0","dark":"1","date":"2016-03-13 00:00:00"})
    CreateMatch({"matchID":1,"score":"205000","difficulty":"Hard","mode":1,"order":"Normal","horde":"Normal","random":"AllPick","fire":"3","water":"0","nature":"3","earth":"0","light":"2","dark":"1","date":"2016-03-10 00:00:00"})
    CreateMatch({"matchID":1,"score":"215000","difficulty":"Hard","mode":0,"order":"1","horde":"1","random":"AllRandom","fire":"2","water":"3","nature":"3","earth":"1","light":"3","dark":"0","date":"2016-03-07 00:00:00"})
    CreateMatch({"matchID":1,"score":"100000","difficulty":"Hard","mode":0,"order":"1","horde":"Normal","random":"AllPick","fire":"3","water":"2","nature":"3","earth":"0","light":"3","dark":"0","date":"2016-03-05 00:00:00"})
    CreateMatch({"matchID":1,"score":"10550","difficulty":"Normal","mode":1,"order":"Normal","horde":"Normal","random":"AllRandom","fire":"0","water":"0","nature":"3","earth":"1","light":"3","dark":"0","date":"2016-03-01 00:00:00"})
    CreateMatch({"matchID":1,"score":"9000","difficulty":"Normal","mode":0,"order":"Normal","horde":"Normal","random":"AllPick","fire":"1","water":"1","nature":"1","earth":"2","light":"2","dark":"2","date":"2016-02-29 00:00:00"})

    ShowFriendRanks("classic")
}

// This is shared by both active and inactive pass
function ToggleHeader() {
    if (!bHasPass)
        ToggleInactivePreview()
    else
    {
        ToggleProfile()
        PreviewMenu.AddClass("Hide")
    }
}

function ToggleInactivePreview() {
    // If any of the two panels is open, close
    if (!CustomBuilders.BHasClass("Hide") || !Profile.BHasClass("Hide"))
        GameUI.CloseProfilePanels()
    else
        Profile.RemoveClass("Hide")

    PreviewMenu.ToggleClass("Hide")

    if (!PreviewMenu.BHasClass("Hide"))
        PreviewProfile()
}

function ToggleProfile() {
    Profile.ToggleClass("Hide")

    if (!bHasPass)
    {
        SetPreviewProfile()
        return
    }

    // Load self in the background
    if (Profile.BHasClass("Hide"))
    {
        Game.EmitSound("ui_quit_menu_fadeout")
        LoadLocalProfile()
    }
    else
    {
        Game.EmitSound("ui_goto_player_page")
        GameUI.CloseLeaderboard()
        GameUI.CloseTowerTable()
    }

    CloseCustomBuilders()
}

function CloseProfile() {
    Profile.AddClass("Hide")
}
function CloseCustomBuilders() {
    CustomBuilders.AddClass("Hide")
    ResetButton.AddClass("Hide")
}
function ClosePreview() {
    PreviewMenu.AddClass("Hide")
}

GameUI.CloseProfilePanels = function() {
    CustomBuilders.AddClass("Hide")
    Profile.AddClass("Hide")
}

function ToggleCustomBuilders() {
    Game.EmitSound("ui_generic_button_click")
    CustomBuilders.ToggleClass("Hide")
    ResetButton.ToggleClass("Hide")

    if (!CustomBuilders.BHasClass("Hide"))
    {
        AnimateBuildersSpawn()
        GameUI.CloseLeaderboard()
        GameUI.CloseTowerTable()
    }

    CloseProfile()
}

function OpenCustomBuilders() {
    CustomBuilders.RemoveClass("Hide")
    AnimateBuildersSpawn()
    CloseProfile()
    $("#preview_builders").AddClass("PerkActive")
    $("#preview_profile").RemoveClass("PerkActive")
    $("#preview_friends").RemoveClass("PerkActive")
    $("#preview_stats").RemoveClass("PerkActive")
    $("#preview_matches").RemoveClass("PerkActive")
    $("#preview_achievements").RemoveClass("PerkActive")
}

function PreviewProfile() {
    Profile.RemoveClass("Hide")

    $("#preview_profile").AddClass("PerkActive")
    $("#preview_friends").AddClass("PerkActive")
    ShowProfileTab('stats')

    CustomBuilders.AddClass("Hide")
}

var LB_types = ["classic","express","frogs"]
function ShowFriendRanks(leaderboard_type) {
    for (var i = 0; i < LB_types.length; i++) {
        var name = LB_types[i]
        var panel = $("#"+name+"_radio")
        panel.SetHasClass( "ActiveTab", LB_types[i] == leaderboard_type )
    };

    Game.EmitSound("ui_rollover_micro")

    currentLB = LB_types.indexOf(leaderboard_type)
    GetPlayerFriends(currentProfile, currentLB)
}

var leftNames = ["stats","matches","achievements"]
function ShowProfileTab ( tabName ) {
    // Toggle from custom builder panel
    Profile.RemoveClass("Hide")
    CustomBuilders.AddClass("Hide")
    $("#preview_builders").RemoveClass("PerkActive")
    $("#preview_profile").AddClass("PerkActive")
    $("#preview_friends").AddClass("PerkActive")

    // Swap radio buttons and panel visibility
    for (var i = 0; i < leftNames.length; i++) {
        var name = leftNames[i]

        var radio = $("#"+name+"_radio")
        if (radio)
            radio.SetHasClass( "ActiveTab", name == tabName )

        var tabPanel = $("#"+name+"_Tab")
        if (tabPanel)
            tabPanel.SetHasClass( "Hide", name != tabName )

        var preview = $("#preview_"+name)
        if (preview)
            preview.SetHasClass( "PerkActive", name == tabName )
    };

    Game.EmitSound("ui_rollover_micro")
}

function MakeButtonVisible() {
    $("#PassPreview").SetHasClass("Hide", bHasPass)
    $("#PassAccess").SetHasClass("Hide", !bHasPass)

    if (bHasPass)
        LoadLocalProfile()
    else
        SetPreviewProfile()
}

function LoadLocalProfile() {
    var steamID64 = GameUI.GetLocalPlayerSteamID()

    // Never reload dummy profile
    if (currentProfile == dummyProfile)
        return

    // Only load local if haven't done so yet
    if (GameUI.ConvertID64(currentProfile) != steamID64)
        LoadProfile(steamID64)
}

function CheckHUDFlipped() {
    var bFlipped = Game.IsHUDFlipped()
    $("#ProfileToggleContainer").SetHasClass("Flipped", bFlipped)
    $("#New").SetHasClass("Flipped", bFlipped)
    $("#MenuArrow").SetHasClass("Flipped", bFlipped)
    $.Schedule(1, CheckHUDFlipped)
}

function CheckProfile() {
    bHasPass = GameUI.PlayerHasProfile(Game.GetLocalPlayerID())

    $("#PassPreview").SetHasClass("Hide", bHasPass)
    $("#PassAccess").SetHasClass("Hide", !bHasPass)

    $.Schedule(1, CheckProfile)
}

(function () {
    $.Schedule(0.1, function()
    {
        CheckProfile()
        MakeButtonVisible()
        GameUI.AcceptWheel()
        CheckHUDFlipped()
    })
})();