$.Msg( "Compiled Panorama Scripts!" );

(function () {
	// DOTAHud Hud
	var hud = $.GetContextPanel().GetParent().GetParent().GetParent();

	// Load Simple Scoreboard underneath shop panel
	var newPanel = $.CreatePanel("Panel", hud, "SimpleScoreboard");
	newPanel.BLoadLayout( "file://{resources}/layout/custom_game/simple_scoreboard.xml", false, false );

	// Hide Topbar background
	var topbar = hud.FindChildTraverse("HUDElements").FindChildTraverse("topbar").FindChildTraverse("HUDSkinTopBarBG");
	topbar.style.visibility = "collapse";

	// Remove talent tree and backpack
	var newUI = hud.FindChildTraverse("HUDElements").FindChildTraverse("lower_hud").FindChildTraverse("center_with_stats").FindChildTraverse("center_block");
	//try the neat way to remove the tree itself
	//newUI.FindChildTraverse("StatBranch").AddClass("NonHero");
	//that bar that grows from level 1 to 25 is annoying
	newUI.FindChildTraverse("StatBranch").FindChildTraverse("StatBranchGraphics").FindChildTraverse("StatBranchChannel").style.visibility = "collapse";
	newUI.FindChildTraverse("StatBranch").FindChildTraverse("StatBranchBG").style.visibility = "collapse";

	//you are not spawning the talent UI, fuck off
	newUI.FindChildTraverse("StatBranch").SetPanelEvent("onmouseover", function(){});
	newUI.FindChildTraverse("StatBranch").SetPanelEvent("onactivate", function(){});
	//fuck backpack UI (We have Lua filling these slots with junk, and if the player can't touch them it should be effectively disabled)
	newUI.FindChildTraverse("inventory").FindChildTraverse("inventory_items").FindChildTraverse("inventory_backpack_list").style.visibility = "collapse";

	// Hide Secondary Inventory
	newUI.FindChildTraverse("right_flare").style.visibility = "collapse";
	newUI.FindChildTraverse("inventory_composition_layer_container").style.visibility = "collapse";

	// Remove Scan and Glyph
	var glyphScanContainer = hud.FindChildTraverse("HUDElements").FindChildTraverse("minimap_container").FindChildTraverse("GlyphScanContainer");
	glyphScanContainer.style.visibility = "collapse";

	// Fix side info panel
	var gameinfo = hud.FindChildTraverse("CustomUIRoot").FindChildTraverse("CustomUIContainer_GameInfo");
	gameinfo.FindChildTraverse("GameInfoPanel").style['margin-top'] = "0px";
	gameinfo.FindChildTraverse("GameInfoButton").style.transform = "translateY(120px)";

	// Fix gap next to abilities from ability tree
	newUI.FindChildTraverse("StatBranch").style.visibility = "collapse";

	$.Msg('700 Workarounds Loaded');
})();