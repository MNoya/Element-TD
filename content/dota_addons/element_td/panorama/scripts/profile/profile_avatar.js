var Root = $.GetContextPanel()
var statsURL = "http://hatinacat.com/leaderboard/data_request.php?req=stats&id="
var Ranks = $("#AvatarCurrentRanks")
var Badges = $("#AvatarBestBadges")
var Loading = $("#Loading")
var Pass = $("#EleTDPass")
var border = $("#favorite_element_border")
var maxBadges = 4

Root.Show = function() {
    UpdateSteamIDFields()

    var avatar = Root.avatar
    var pos = avatar.GetPositionWithinWindow()
    var relation = 1080 / Root.GetParent().actuallayoutheight;
    var posX = (pos.x+avatar.actuallayoutwidth)*relation
    var posY = pos.y*relation
    Root.style.x = posX + "px";
    Root.style.y = posY + "px";
    Root.RemoveClass("Hide")

    GameUI.ApplyPanelBorder(Root, Root.steamID64)
}

Root.Hide = function() {
    Root.AddClass("Hide")
}

function RequestData() {
    var steamID64 = Root.steamID64
    var steamID32 = GameUI.ConvertID32(steamID64)
    $.Msg("Getting data for "+steamID32+"...")
    Loading.RemoveClass("Hide")

    $.AsyncWebRequest( statsURL+steamID32, { type: 'GET', 
        success: function( data ) {
            var info = JSON.parse(data);
            var player_info = info["player"]

            if (player_info)
            {
                $("#favorite_element").SetImage("file://{resources}/images/custom_game/resources/"+player_info["allTime"]["favouriteElement"]+".png");

                if (player_info["rank"] || player_info["rank_exp"] || player_info["rank_frogs"])
                    SetAvatarRanks(player_info)

                if (player_info["milestones"])
                    CreateAvatarBadges(player_info)
            }
            Loading.AddClass("Hide")
            $("#FavoriteElementPanel").RemoveClass("Hide")
        },

        error: function() {
            Loading.AddClass("Hide")
        }
    })

    GameUI.CheckPlayerPass(steamID64, function(hasPass) {
        Pass.SetHasClass("Hide", !hasPass)

        if (hasPass)
        {
            border.SetImage("s2r://panorama/images/profile_badges/bg_02_psd.vtex")
            border.AddClass("hasPass")
        }
        else
        {
           border.SetImage("s2r://panorama/images/profile_badges/bg_01_psd.vtex")
        }
    })
}

function SetAvatarRanks (player_info) {
    Ranks.RemoveClass("Hide")
    $("#ClassicRank").text = (player_info["rank"] === undefined) ? "--" : GameUI.FormatRank(player_info["rank"]);
    $("#ExpressRank").text = (player_info["rank_exp"] === undefined) ? "--" : GameUI.FormatRank(player_info["rank_exp"]);
    $("#FrogsRank").text = (player_info["rank_frogs"] === undefined) ? "--" : GameUI.FormatRank(player_info["rank_frogs"]);
}

function CreateAvatarBadges(player_info) {
    var milestones = player_info["milestones"]
    var bestBadges = {} //Newest

    // Newer first
    var milestones_array = []
    for (version in milestones) {
        milestones_array.unshift(version)
    }

    for (var i in milestones_array) 
    {
        var version = milestones_array[i]
        var rank_classic = milestones[version]["normal_rank"]
        var rank_express = milestones[version]["express_rank"]

        // Choose the best to show for the version
        var singleRank = {}
        if (rank_classic && rank_express)
        {
            singleRank.rank_classic = rank_classic
            singleRank.percentile_classic = rank_classic / milestones[version]["normal_count"] * 100
            singleRank.rank_express = rank_express
            singleRank.percentile_express = rank_express / milestones[version]["express_count"] * 100

            if (singleRank.percentile_classic < singleRank.percentile_express)
            {
                singleRank.bestRank = rank_classic
                singleRank.rank_express = 0
                singleRank.percentile_express = 0
            }
            else
            {
                singleRank.bestRank = rank_express
                singleRank.rank_classic = 0
                singleRank.percentile_classic = 0
            }
        }
        else if (rank_classic)
        {
            singleRank.bestRank = rank_classic
            singleRank.rank_classic = rank_classic
            singleRank.percentile_classic = rank_classic / milestones[version]["normal_count"] * 100
            singleRank.rank_express = 0
            singleRank.percentile_express = 0
        }
        else if (rank_express)
        {
            singleRank.bestRank = rank_express
            singleRank.rank_classic = 0
            singleRank.percentile_classic = 0
            singleRank.rank_express = rank_express
            singleRank.percentile_express = rank_express / milestones[version]["express_count"] * 100
        }

        if (singleRank.bestRank)
            bestBadges[version] = singleRank
    }

    // Iterate this list calling CreateBadges
    var badgesCreated = 0
    for (var v in bestBadges)
    {
        if (bestBadges[v].rank_classic || bestBadges[v].rank_express)
        {
            GameUI.CreateBadges(Badges, GameUI.FormatVersion(v), bestBadges[v].rank_classic, bestBadges[v].percentile_classic, bestBadges[v].rank_express, bestBadges[v].percentile_express)
            badgesCreated++
        }

        if (badgesCreated >= maxBadges)
            break;
    }

    Badges.SetHasClass("Hide", badgesCreated == 0)
}


function ShowPlayerPass(steamID64) {
    var steamID = GameUI.ConvertID32(steamID64)

    $.AsyncWebRequest( "http://hatinacat.com/leaderboard/data_request.php?req=save&id="+steamID, { type: 'GET', 
        success: function( data ) {
            var info = JSON.parse(data);
            var save = info["save"]

            $.Msg(save)
        }
    })
}

function UpdateSteamIDFields() {
    $("#AvatarImage").steamid = Root.steamID64 //Set in code before the layout is loaded
    $("#AvatarUserName").steamid = Root.steamID64
}

function Setup() {
    UpdateSteamIDFields()
    RequestData()
}

Setup()