"use strict";

var teamScores = [0,0,0,0];

var playerWave = [0,0,0,0,0,0,0,0];
var playerHealth = [100,100,100,100,100,100,100,100];
var playerScore = [0,0,0,0,0,0,0,0];
var playerData = {};

//=============================================================================
//=============================================================================
function _ScoreboardUpdater_SetTextSafe( panel, childName, textValue )
{
    if ( panel === null )
        return;
    var childPanel = panel.FindChildInLayoutFile( childName )
    if ( childPanel === null )
        return;
    childPanel.text = textValue;
}

function _ScoreboardUpdater_SetDed( panel, childName )
{
    if ( panel === null )
        return;
    var childPanel = panel.FindChildInLayoutFile( childName )
    if ( childPanel === null )
        return;
    if (childPanel.ded !== undefined)
    {
        childPanel.ded = $.CreatePanel("Image", childPanel, '')
        ded.AddClass("RIP")
    }
}

//=============================================================================
//=============================================================================
function _ScoreboardUpdater_UpdatePlayerPanel( scoreboardConfig, playersContainer, playerId, localPlayerTeamId )
{
    var playerPanelName = "_dynamic_player_" + playerId;
//  $.Msg( playerPanelName );
    var playerPanel = playersContainer.FindChild( playerPanelName );
    if ( playerPanel === null )
    {
        playerPanel = $.CreatePanel( "Panel", playersContainer, playerPanelName );
        playerPanel.SetAttributeInt( "player_id", playerId );
        playerPanel.BLoadLayout( scoreboardConfig.playerXmlName, false, false );
    }

    playerPanel.SetHasClass( "is_local_player", ( playerId == Game.GetLocalPlayerID() ) );
    
    var ultStateOrTime = PlayerUltimateStateOrTime_t.PLAYER_ULTIMATE_STATE_HIDDEN; // values > 0 mean on cooldown for that many seconds
    var goldValue = -1;
    var isTeammate = false;

    var playerInfo = Game.GetPlayerInfo( playerId );
    if ( playerInfo )
    {
        goldValue = playerInfo.player_gold;
        isTeammate = ( playerInfo.player_team_id == localPlayerTeamId );
        
        ultStateOrTime = Game.GetPlayerUltimateStateOrTime( playerId );
        _ScoreboardUpdater_SetTextSafe( playerPanel, "TeammateGoldAmount", goldValue );

        playerPanel.SetHasClass( "is_player", true );
        playerPanel.SetHasClass( "player_dead", ( playerInfo.player_respawn_seconds >= 0 ) );
        playerPanel.SetHasClass( "local_player_teammate", isTeammate && ( playerId != Game.GetLocalPlayerID() ) );

        _ScoreboardUpdater_SetTextSafe( playerPanel, "PlayerName", playerInfo.player_name );
        _ScoreboardUpdater_SetTextSafe( playerPanel, "Level", playerInfo.player_level );
        //_ScoreboardUpdater_SetTextSafe( playerPanel, "Deaths", playerInfo.player_deaths );
        //_ScoreboardUpdater_SetTextSafe( playerPanel, "Assists", playerInfo.player_assists );
        _ScoreboardUpdater_SetTextSafe( playerPanel, "Score", GameUI.CustomUIConfig().playerScore[playerId] );
        _ScoreboardUpdater_SetTextSafe( playerPanel, "Wave", GameUI.CustomUIConfig().playerWave[playerId] );
        _ScoreboardUpdater_SetTextSafe( playerPanel, "Health", playerHealth[playerId] );

        if ( GameUI.CustomUIConfig().playerData[playerId] !== undefined )
        {
            _ScoreboardUpdater_SetTextSafe( playerPanel, "Lives", GameUI.CustomUIConfig().playerData[playerId].lives);
            _ScoreboardUpdater_SetTextSafe( playerPanel, "TeammateLumberAmount", GameUI.CustomUIConfig().playerData[playerId].lumber);
            _ScoreboardUpdater_SetTextSafe( playerPanel, "TeammateEssenceAmount", GameUI.CustomUIConfig().playerData[playerId].pureEssence);
            _ScoreboardUpdater_SetTextSafe( playerPanel, "Towers", GameUI.CustomUIConfig().playerData[playerId].towers);
            _ScoreboardUpdater_SetTextSafe( playerPanel, "PlayerGoldAmount", GameUI.CustomUIConfig().playerData[playerId].gold );
            _ScoreboardUpdater_SetTextSafe( playerPanel, "Networth", GameUI.CustomUIConfig().playerData[playerId].networth );
            
            var icefrogKills = GameUI.CustomUIConfig().playerData[playerId].iceFrogKills

            if (GameUI.CustomUIConfig().playerData[playerId].remaining !== undefined)
            {
                _ScoreboardUpdater_SetTextSafe( playerPanel, "Kills", GameUI.CustomUIConfig().playerData[playerId].remaining );
            }
            else
            {
                if (GameUI.CustomUIConfig().playerData[playerId].lives !== undefined && GameUI.CustomUIConfig().playerData[playerId].lives == 0)
                {
                    _ScoreboardUpdater_SetTextSafe( playerPanel, "Kills", "["+GameUI.CustomUIConfig().playerData[playerId].lastHits+"]" );
                    _ScoreboardUpdater_SetTextSafe( playerPanel, "KillsEnd", GameUI.CustomUIConfig().playerData[playerId].lastHits );
                }
            }

            if (GameUI.CustomUIConfig().playerData[playerId].express_end == 1)
            {
                _ScoreboardUpdater_SetTextSafe( playerPanel, "Kills", "["+GameUI.CustomUIConfig().playerData[playerId].lastHits+"]" );
                _ScoreboardUpdater_SetTextSafe( playerPanel, "KillsEnd", GameUI.CustomUIConfig().playerData[playerId].lastHits );
            }
            
            if (icefrogKills > 0)
            {
                var frogs = playerPanel.FindChildTraverse( "OSfrog" )
                if (frogs !== null)
                    frogs.RemoveClass("hide")

                var kRemaining = $("#KillsRemaining")
                if (kRemaining !== null)
                    kRemaining.text = "KILLS"

                _ScoreboardUpdater_SetTextSafe( playerPanel, "Kills", icefrogKills );
                var killsPanel = playerPanel.FindChildTraverse( "Kills" )
                if (killsPanel !== null)
                {
                    killsPanel.RemoveClass('Kills_Standard')
                    killsPanel.AddClass('Kills_Frog')
                }

                _ScoreboardUpdater_SetTextSafe( playerPanel, "KillsEnd", icefrogKills );
                var killsPanelEnd = playerPanel.FindChildTraverse( "KillsEnd" )
                if (killsPanelEnd !== null)
                {
                    killsPanelEnd.RemoveClass('Kills_Standard')
                    killsPanelEnd.AddClass('Kills_Frog')
                }
            }

            var elements = GameUI.CustomUIConfig().playerData[playerId].elements
            for (var elem in elements)
            {
                var level = elements[elem]
                var elementPanel = playerPanel.FindChildTraverse( elem )
                if (elementPanel !== null)
                {
                    if (level==0)
                        elementPanel.AddClass("hide")
                    else
                    {
                        elementPanel.RemoveClass("hide")
                        var elem_level = playerPanel.FindChildTraverse( elem+"_level" )
                        if (elem_level !== null)
                        {
                            elem_level.text = level
                        }
                    }
                }
            }

            if (GameUI.CustomUIConfig().playerData[playerId].randomed)
            {
                var randomedPanel = playerPanel.FindChildTraverse( "HasRandomed" );
                if (randomedPanel !== null)
                {
                    randomedPanel.RemoveClass("hide");
                    randomedPanel.AddClass( "Random");
                    randomedPanel.text = "R"
                }
            }

            /*var difficulty = GameUI.CustomUIConfig().playerData[playerId].difficulty;
            var diff = "-";
            if (difficulty == "Normal")
                diff = "N";
            else if (difficulty == "Hard")
                diff = "H";
            else if (difficulty == "VeryHard")
                diff = "VH";
            else if (difficulty == "Insane")
                diff = "I";
            _ScoreboardUpdater_SetTextSafe( playerPanel, "Difficulty", diff);
            var diffPanel = playerPanel.FindChildInLayoutFile( "Difficulty" );
            if ( diffPanel )
            {
                diffPanel.SetHasClass( "Normal", diff == "N");
                diffPanel.SetHasClass( "Hard", diff == "H");
                diffPanel.SetHasClass( "VeryHard", diff == "VH");
                diffPanel.SetHasClass( "Insane", diff == "I");
            }*/
        }

        var playerName = playerPanel.FindChildInLayoutFile( "PlayerName" );
        if ( playerName )
        {
            var playerColor = GameUI.CustomUIConfig().team_colors[playerInfo.player_team_id];
            playerName.style['color'] = playerColor;
        }

        var playerPortrait = playerPanel.FindChildInLayoutFile( "HeroIcon" );
        if ( playerPortrait )
        {
            if ( playerInfo.player_selected_hero !== "" )
            {
                playerPortrait.SetImage( "file://{images}/heroes/" + playerInfo.player_selected_hero + ".png" );
            }
            else
            {
                playerPortrait.SetImage( "file://{images}/custom_game/unassigned.png" );
            }
        }
        
        if ( playerInfo.player_selected_hero_id == -1 )
        {
            _ScoreboardUpdater_SetTextSafe( playerPanel, "HeroName", $.Localize( "#DOTA_Scoreboard_Picking_Hero" ) )
        }
        else
        {
            _ScoreboardUpdater_SetTextSafe( playerPanel, "HeroName", $.Localize( "#"+playerInfo.player_selected_hero ) )
        }
        
        var heroNameAndDescription = playerPanel.FindChildInLayoutFile( "HeroNameAndDescription" );
        if ( heroNameAndDescription )
        {
            if ( playerInfo.player_selected_hero_id == -1 )
            {
                heroNameAndDescription.SetDialogVariable( "hero_name", $.Localize( "#DOTA_Scoreboard_Picking_Hero" ) );
            }
            else
            {
                heroNameAndDescription.SetDialogVariable( "hero_name", $.Localize( "#"+playerInfo.player_selected_hero ) );
            }
            heroNameAndDescription.SetDialogVariableInt( "hero_level",  playerInfo.player_level );
        }       

        playerPanel.SetHasClass( "player_connection_abandoned", playerInfo.player_connection_state == DOTAConnectionState_t.DOTA_CONNECTION_STATE_ABANDONED );
        playerPanel.SetHasClass( "player_connection_failed", playerInfo.player_connection_state == DOTAConnectionState_t.DOTA_CONNECTION_STATE_FAILED );
        playerPanel.SetHasClass( "player_connection_disconnected", playerInfo.player_connection_state == DOTAConnectionState_t.DOTA_CONNECTION_STATE_DISCONNECTED );

        var playerAvatar = playerPanel.FindChildInLayoutFile( "AvatarImage" );
        if ( playerAvatar )
        {
            playerAvatar.steamid = playerInfo.player_steamid;
        }       

        var playerColorBar = playerPanel.FindChildInLayoutFile( "PlayerColorBar" );
        if ( playerColorBar !== null )
        {
            if ( GameUI.CustomUIConfig().team_colors )
            {   
                var playerColor = GameUI.CustomUIConfig().team_colors[playerInfo.player_team_id];
                if (playerColor == null)
                    playerColor = "#999999";
                playerColorBar.style.backgroundColor = playerColor;
            }
            else
            {
                var playerColor = "#999999";
                playerColorBar.style.backgroundColor = playerColor;
            }
        }
        var playerWavePanel = playerPanel.FindChildInLayoutFile( "PlayerWave" );
        if ( playerWavePanel !== null )
        {
            playerWavePanel.text = playerWave[playerId];
        }
        var playerHealthBar = playerPanel.FindChildInLayoutFile( "HealthIndicatorHealth" );
        if ( playerHealthBar !== null )
        {
            playerHealthBar.SetHasClass( "low_health", (playerHealth[playerId] <= 30) );
            playerHealthBar.style.width = playerHealth[playerId] + "%";
        }
        var playerScoreLabel = playerPanel.FindChildInLayoutFile( "ScoreTooltip" );
        if ( playerScoreLabel !== null )
        {
            playerScoreLabel.text = playerScore[playerId];
        }
    }
    else
    {
        playerPanel.SetHasClass( "is_player", false );
        _ScoreboardUpdater_SetTextSafe( playerPanel, "PlayerName", "" );
        _ScoreboardUpdater_SetTextSafe( playerPanel, "HeroName", "")
        _ScoreboardUpdater_SetTextSafe( playerPanel, "Level", "" );
        _ScoreboardUpdater_SetTextSafe( playerPanel, "Kills", "-" );
        _ScoreboardUpdater_SetTextSafe( playerPanel, "Deaths", "-" );
        _ScoreboardUpdater_SetTextSafe( playerPanel, "Assists", "-" );
        _ScoreboardUpdater_SetTextSafe( playerPanel, "HeroNameAndDescription", "" );
        _ScoreboardUpdater_SetTextSafe( playerPanel, "TeammateGoldAmount", "0" );
    }

    var playerItemsContainer = playerPanel.FindChildInLayoutFile( "PlayerItemsContainer" );
    if ( playerItemsContainer )
    {
        var playerItems = Game.GetPlayerItems( playerId );
        if ( playerItems )
        {
    //      $.Msg( "playerItems = ", playerItems );
            for ( var i = playerItems.inventory_slot_min; i < playerItems.inventory_slot_max; ++i )
            {
                var itemPanelName = "_dynamic_item_" + i;
                var itemPanel = playerItemsContainer.FindChild( itemPanelName );
                if ( itemPanel === null )
                {
                    itemPanel = $.CreatePanel( "Image", playerItemsContainer, itemPanelName );
                    itemPanel.AddClass( "PlayerItem" );
                }

                var itemInfo = playerItems.inventory[i];
                if ( itemInfo )
                {
                    var item_image_name = "file://{images}/custom_game/items/" + itemInfo.item_name.replace( "item_", "" ) + ".png";
                    itemPanel.SetImage( item_image_name );
                }
                else
                {
                    itemPanel.SetImage( "" );
                }
            }
        }
    }

    playerPanel.SetHasClass( "player_ultimate_ready", ( ultStateOrTime == PlayerUltimateStateOrTime_t.PLAYER_ULTIMATE_STATE_READY ) );
    playerPanel.SetHasClass( "player_ultimate_no_mana", ( ultStateOrTime == PlayerUltimateStateOrTime_t.PLAYER_ULTIMATE_STATE_NO_MANA) );
    playerPanel.SetHasClass( "player_ultimate_not_leveled", ( ultStateOrTime == PlayerUltimateStateOrTime_t.PLAYER_ULTIMATE_STATE_NOT_LEVELED) );
    playerPanel.SetHasClass( "player_ultimate_hidden", ( ultStateOrTime == PlayerUltimateStateOrTime_t.PLAYER_ULTIMATE_STATE_HIDDEN) );
    playerPanel.SetHasClass( "player_ultimate_cooldown", ( ultStateOrTime > 0 ) );
    _ScoreboardUpdater_SetTextSafe( playerPanel, "PlayerUltimateCooldown", ultStateOrTime );
}


//=============================================================================
//=============================================================================
function _ScoreboardUpdater_UpdateTeamPanel( scoreboardConfig, containerPanel, teamDetails, teamsInfo )
{

    if ( !containerPanel )
        return;

    var teamId = teamDetails.team_id;
//  $.Msg( "_ScoreboardUpdater_UpdateTeamPanel: ", teamId );

    var teamPanelName = "_dynamic_team_" + teamId;
    var teamPanel = $( "#"+teamPanelName );
    if ( teamPanel === null )
    {
        return;
//      $.Msg( "UpdateTeamPanel.Create: ", teamPanelName, " = ", scoreboardConfig.teamXmlName );
        teamPanel = $.CreatePanel( "Panel", containerPanel, teamPanelName );
        teamPanel.SetAttributeInt( "team_id", teamId );
        teamPanel.BLoadLayout( scoreboardConfig.teamXmlName, false, false );

        var logo_xml = GameUI.CustomUIConfig().team_logo_xml;
        if ( logo_xml )
        {
            var teamLogoPanel = teamPanel.FindChildInLayoutFile( "TeamLogo" );
            if ( teamLogoPanel )
            {
                teamLogoPanel.SetAttributeInt( "team_id", teamId );
                teamLogoPanel.BLoadLayout( logo_xml, false, false );
            }
        }
    }
    var localPlayerTeamId = -1;
    var localPlayer = Game.GetLocalPlayerInfo();
    if ( localPlayer )
    {
        localPlayerTeamId = localPlayer.player_team_id;
    }
    teamPanel.SetHasClass( "local_player_team", localPlayerTeamId == teamId );
    teamPanel.SetHasClass( "not_local_player_team", localPlayerTeamId != teamId );

    var teamPlayers = Game.GetPlayerIDsOnTeam( teamId );
    var playersContainer = teamPanel.FindChildInLayoutFile( "PlayersContainer" );

    if ( playersContainer )
    {
        if (playersContainer.layoutfile.indexOf("top_scoreboard.xml") > -1)
        {
            for (var player of teamPlayers)
            {
                _ScoreboardUpdater_UpdatePlayerPanel( scoreboardConfig, playersContainer, player, localPlayerTeamId );
            }
            if (teamPlayers.length == 0)
            {
                _ScoreboardUpdater_UpdatePlayerPanel( scoreboardConfig, playersContainer, 10, -1 );
            }
        }
        else
        {
            for (var player of teamPlayers)
            {
                _ScoreboardUpdater_UpdatePlayerPanel( scoreboardConfig, playersContainer, player, localPlayerTeamId );
            }  
        }
    }
    
    teamPanel.SetHasClass( "no_players", (teamPlayers.length == 0) )
    teamPanel.SetHasClass( "one_player", (teamPlayers.length == 1) )
    teamPanel.SetHasClass( "many_players", (teamPlayers.length > 5) )
    
    if ( teamsInfo.max_team_players < teamPlayers.length )
    {
        teamsInfo.max_team_players = teamPlayers.length;
    }

    //_ScoreboardUpdater_SetTextSafe( teamPanel, "TeamScore", teamScores[teamId] )
    _ScoreboardUpdater_SetTextSafe( teamPanel, "TeamName", $.Localize( teamDetails.team_name ) )
    
    if ( GameUI.CustomUIConfig().team_colors )
    {
        var teamColor = GameUI.CustomUIConfig().team_colors[ teamId ];
        var teamColorPanel = teamPanel.FindChildInLayoutFile( "TeamColor" );
        
        teamColor = teamColor.replace( ";", "" );

        if ( teamColorPanel )
        {
            teamNamePanel.style.backgroundColor = teamColor + ";";
        }
        
        var teamColor_GradentFromTransparentLeft = teamPanel.FindChildInLayoutFile( "TeamColor_GradentFromTransparentLeft" );
        if ( teamColor_GradentFromTransparentLeft )
        {
            var gradientText = 'gradient( linear, 0% 0%, 800% 0%, from( #00000000 ), to( ' + teamColor + ' ) );';
//          $.Msg( gradientText );
            teamColor_GradentFromTransparentLeft.style.backgroundColor = gradientText;
        }
    }
    
    return teamPanel;
}

//=============================================================================
//=============================================================================
function _ScoreboardUpdater_UpdateAllTeamsAndPlayers( scoreboardConfig, teamsContainer )
{
    var teamsList = [];
    for ( var teamId of Game.GetAllTeamIDs() )
    {
        teamsList.push( Game.GetTeamDetails( teamId ) );
    }

    // update/create team panels
    var teamsInfo = { max_team_players: 1 };
    var panelsByTeam = [];
    for ( var i = 0; i < teamsList.length; ++i )
    {
        var teamPanel = _ScoreboardUpdater_UpdateTeamPanel( scoreboardConfig, teamsContainer, teamsList[i], teamsInfo );
        if ( teamPanel )
        {
            panelsByTeam[ teamsList[i].team_id ] = teamPanel;
        }
    }
}


//=============================================================================
//=============================================================================
function ScoreboardUpdater_InitializeScoreboard( scoreboardConfig, scoreboardPanel )
{
    GameUI.CustomUIConfig().teamsPrevPlace = [];
    if ( typeof(scoreboardConfig.shouldSort) === 'undefined')
    {
        // default to true
        scoreboardConfig.shouldSort = false;
    }
    _ScoreboardUpdater_UpdateAllTeamsAndPlayers( scoreboardConfig, scoreboardPanel );
    return { "scoreboardConfig": scoreboardConfig, "scoreboardPanel":scoreboardPanel }
}


//=============================================================================
//=============================================================================
function ScoreboardUpdater_SetScoreboardActive( scoreboardHandle, isActive )
{
    if ( scoreboardHandle.scoreboardConfig === null || scoreboardHandle.scoreboardPanel === null )
    {
        return;
    }
    
    if ( isActive )
    {
        _ScoreboardUpdater_UpdateAllTeamsAndPlayers( scoreboardHandle.scoreboardConfig, scoreboardHandle.scoreboardPanel );
    }
}

//=============================================================================
//=============================================================================
function ScoreboardUpdater_GetTeamPanel( scoreboardHandle, teamId )
{
    if ( scoreboardHandle.scoreboardPanel === null )
    {
        return;
    }
    
    var teamPanelName = "_dynamic_team_" + teamId;
    return scoreboardHandle.scoreboardPanel.FindChild( teamPanelName );
}

//=============================================================================
//=============================================================================
function ScoreboardUpdater_GetSortedTeamInfoList( scoreboardHandle )
{
    var teamsList = [];
    /*for ( var teamId of Game.GetAllTeamIDs() )
    {
        teamsList.push( Game.GetTeamDetails( teamId ) );
    }*/

    // Sort teams by player score
    var sortedScores = GameUI.CustomUIConfig().playerScore.sort(function(a, b){return b-a});
    for (var i = 0; i < 8; i++)
    {
        var playerID = GetPlayerWithScore(sortedScores[i])
        if (Players.IsValidPlayerID(playerID))
        {
            teamsList.push( Game.GetTeamDetails( Players.GetTeam(playerID) ) );
        }
    };

    return teamsList;
}

function GetPlayerWithScore(value) {
    var scores = GameUI.CustomUIConfig().playerScore
    for (var playerID in scores)
    {
        var thisScore = scores[playerID]
        if (thisScore == value)
            return Number(playerID)
    }
    return -1
}

function SetTopBarValue( data )
{
    teamScores[data.teamId] = data.teamScore;
}

function SetTopBarWaveValue( data )
{
    playerWave[data.playerId] = data.wave;
    GameUI.CustomUIConfig().playerWave[data.playerId] = data.wave;
}

function SetTopBarPlayerHealth( data )
{
    playerHealth[data.playerId] = data.health;
}

function SetTopBarPlayerScore( data )
{
    playerScore[data.playerId] = data.score;
    GameUI.CustomUIConfig().playerScore[data.playerId] = data.score;
}

function SetUpdateScoreboard( data )
{
    playerData[data.playerID] = data.data;
    GameUI.CustomUIConfig().playerData[data.playerID] = data.data;

    //_ScoreboardUpdater_UpdateAllTeamsAndPlayers( scoreboardHandle.scoreboardConfig, scoreboardHandle.scoreboardPanel );
}

function ToggleScoreboard() {
    Game.EmitSound("ui_generic_button_click")
    GameUI.CustomUIConfig().ToggleScoreboard()
}

(function () {
    if (GameUI.CustomUIConfig().playerData === undefined) {
        $.Msg("Initialise PlayerData");
        GameUI.CustomUIConfig().playerData = {};
        GameUI.CustomUIConfig().playerWave = [0,0,0,0,0,0,0,0];
        GameUI.CustomUIConfig().playerScore = [0,0,0,0,0,0,0,0];
    }
    GameEvents.Subscribe( "SetTopBarScoreValue", SetTopBarValue );
    GameEvents.Subscribe( "SetTopBarWaveValue", SetTopBarWaveValue );
    GameEvents.Subscribe( "SetTopBarPlayerHealth", SetTopBarPlayerHealth );
    GameEvents.Subscribe( "SetTopBarPlayerScore", SetTopBarPlayerScore );
    GameEvents.Subscribe( "etd_update_scoreboard", SetUpdateScoreboard );
})();