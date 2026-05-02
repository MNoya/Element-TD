"use strict";

GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_GOLD, false );

var Root = $.GetContextPanel()
var ElementsUI = $( "#ResourceElements" );
var LumberUI = $( "#ResourceLumber" );
var GoldUI = $( "#ResourceGold" );
var PureEssenceUI = $( "#ResourceEssence" );
var ScoreUI = $( "#ResourceScore" );
var MinimapUI = $( "#MinimapOverlay" )
var VersionUI = $("#Version")
var ResourceUnderlay = $("#ResourceUnderlay")

var lumber = $( '#LumberText' );
var gold = $( '#GoldText' );
var pureEssence = $( '#PureEssenceText' );
var score = $( '#ScoreText' );

var lumberDisplay = $( '#LumberDisplay' );

var elements = {water: '#WaterValue', fire: '#FireValue', nature: '#NatureValue', earth: '#EarthValue', light: '#LightValue', dark:'#DarkValue'};

var tooltips = {'#gold':"#tooltip_gold",
				'#lumber':'#tooltip_lumber',
				'#score':'#tooltip_score',
				'#water':'#water_level',
				'#fire':'#fire_level',
				'#nature':'#nature_level',
				'#earth':'#earth_level',
				'#light':'#light_level',
				'#dark':'#dark_level',
				};

var tooltipsUI = {'#gold':GoldUI, '#lumber': LumberUI, '#essence': LumberUI, '#score': ScoreUI,
				  '#water':ElementsUI,'#fire':ElementsUI,
				  '#nature':ElementsUI,'#earth':ElementsUI,
				  '#light':ElementsUI,'#dark':ElementsUI,
				};

function ModifyLumber( data )
{
	var prev = parseInt(lumber.text);
	var diff = data.lumber - prev;
	if (data.lumber != undefined)
	{
		lumber.text = data.lumber;

		// Keep track of the summoner
		Root.summoner = data.summoner
		
		if (diff > 0 && lumberDisplay) {
			lumberDisplay.text = "+" + diff + " Lumber";
			lumberDisplay.visible = true;
			lumberDisplay.AddClass('newResource');
			$.Schedule(3, function(){lumberDisplay.visible = false;lumberDisplay.RemoveClass('newResource');});
		}
	}
	else
		lumber.text = 0;
}

function ModifyGold (data) {
	var prev = parseInt(gold.text);
	if (data.gold != undefined)
	{
		gold.text = data.gold;
		gold.style["margin-right"] = gold.text.length > 5 ? "0px" : "8px";
	}
	else
		gold.text = 0;
}

function ModifyPureEssence( data )
{
	pureEssence.text = data.pureEssence;
}

function ModifyScore( data )
{
	score.text = data.score;
}

function UpdateElements( data )
{
	for(var element in data)
	{
		if( element in elements )
		{
			$(elements[element]).GetParent().SetHasClass( "no_element_levels",  data[element] == 0 );
			$(elements[element]).text = data[element];
		}
	}
}

function ShowTooltip( str )
{
	var tooltip = tooltips[str];
	var tooltipUI = tooltipsUI[str];
	var title = str.replace(/(['"])/g, "\\$1");

	if (str == "#essence")
	{
		if (Game.IsCoop())
			tooltip = '#tooltip_essence_coop'
		else if (Game.IsExpress())
			tooltip = '#tooltip_essence_express'
		else
			tooltip = '#tooltip_essence_classic'
	}
	else
		tooltip = tooltip.replace(/(['"])/g, "\\$1");

	$.DispatchEvent("DOTAShowTitleTextTooltip", tooltipUI, title, tooltip);
}

//Karawasa Resolution 21x9
function CheckAspectRatio()
{
	var width = Root.actuallayoutwidth;
	var height = Root.actuallayoutheight;
	// -w 1978 -h 828 for 'Set Launch Options...'
	if (!width || !height)
	{
		$.Schedule(0.1, CheckAspectRatio);
		return;
	}

	var r = gcd(width, height);

	// Aspect1:Aspect2
	var Aspect1 = width/r;
	var Aspect2 = height/r;

	var AspectRatio = Aspect1 + ":" + Aspect2;
	//$.Msg(AspectRatio);
	
	// 21x9
	Root.SetHasClass("AspectRatio21x9", AspectRatio == "64:27" || AspectRatio == "21:9" || AspectRatio == "43:18");
}

function gcd (a, b) {
	return (b == 0) ? a : gcd (b, a%b);
}

function CheckElementLevelUpAvailable() {
	var ability_points = Entities.GetAbilityPoints(Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer()))
	$("#SelectSummoner").visible = ability_points > 0
	$("#SelectSummoner").text = $.Localize("#DOTA_LevelUp") + ": +" + ability_points
	$.Schedule(0.1, CheckElementLevelUpAvailable)
}

function SelectSummoner() {
	GameUI.SelectUnit(Root.summoner, false)
}

function CheckHudFlipped() {
	Root.SetHasClass("HudFlipped", Game.IsHUDFlipped())
	$.Schedule(1, CheckHudFlipped)
}

function Setup() {
	if (Game.IsCoop())
	{
		$("#Coop").RemoveClass("Hide")
		$("#Version").AddClass("Coop")
		$("#elementTD").AddClass("Hide")
		$("#elementTDGlow").AddClass("Hide")
	}
	
	VersionUI.text = "Version "+CustomNetTables.GetTableValue('gameinfo', 'version').value
    $.Schedule(0.1, CheckHudFlipped)
    $.Schedule(1, CheckAspectRatio)
    $.Schedule(1, CheckElementLevelUpAvailable)
}

(function () {
    Setup()
    GameEvents.Subscribe( "etd_update_lumber", ModifyLumber );
    GameEvents.Subscribe( "etd_update_gold", ModifyGold );
    GameEvents.Subscribe( "etd_update_pure_essence", ModifyPureEssence );
    GameEvents.Subscribe( "etd_update_score", ModifyScore );
    GameEvents.Subscribe( "etd_update_elements", UpdateElements );
})();
