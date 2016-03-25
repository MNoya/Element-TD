(function () {
    var playerID = $.GetContextPanel().GetAttributeInt( "player_id", -1 )

    // Reconnection
    $.Schedule(1, function()
    {
        $("#Avatar").SetPanelEvent( "onmouseover", function() { GameUI.ShowPlayerRank(playerID) })
        $("#Avatar").SetPanelEvent( "onmouseout", function() { GameUI.ShowPlayerRank(playerID) })
        $("#AvatarImage").ClearPanelEvent( "onmouseover" )
        $("#AvatarImage").ClearPanelEvent( "onmouseout" )
        //$("#AvatarImage").ClearPanelEvent( "onactivate" ) 
    })
})();