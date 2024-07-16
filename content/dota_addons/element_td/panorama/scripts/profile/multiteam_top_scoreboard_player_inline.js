
function PortraitClicked()
{
    Players.PlayerPortraitClicked( $.GetContextPanel().GetAttributeInt( "player_id", -1 ), GameUI.IsControlDown(), GameUI.IsAltDown() );
}

(function () {
    var playerID = $.GetContextPanel().GetAttributeInt( "player_id", -1 )

    // Reconnection
    $.Schedule(1, function()
    {
        $("#ScoreboardRoot").SetPanelEvent( "onmouseover", function() { GameUI.ShowPlayerRank(playerID) })
        $("#ScoreboardRoot").SetPanelEvent( "onmouseout", function() { GameUI.HidePlayerRank(playerID) })
        $("#AvatarImage").ClearPanelEvent( "onmouseover" )
        $("#AvatarImage").ClearPanelEvent( "onmouseout" )
        //$("#AvatarImage").ClearPanelEvent( "onactivate" ) 
    })
})();