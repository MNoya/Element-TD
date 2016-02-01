"use strict";

var ElementsUI = $( "#ResourceElements" );
var LumberUI = $( "#ResourceLumber" );
var PureEssenceUI = $( "#ResourceEssence" );
var ScoreUI = $( "#ResourceScore" );

var lumber = $( '#LumberText' );
var pureEssence = $( '#PureEssenceText' );
var score = $( '#ScoreText' );

var lumberDisplay = $( '#LumberDisplay' );

var elements = {water: '#WaterValue', fire: '#FireValue', nature: '#NatureValue', earth: '#EarthValue', light: '#LightValue', dark:'#DarkValue'};

var tooltips = {'Lumber':'Lumber is used to summon elementals at the summoner.<br>You will recieve lumber every 5 rounds (3 rounds on express mode).',
				'Pure Essence':'Essence is used to build your most powerful towers.<br>You can use it to evolve a Level 3 Single-Element Tower, or to build a Periodic Tower if you have all 6 Elements.<br>You can buy Pure Essences from the summoner for 1 lumber.<br>You will recieve 1 pure essence on wave 46 and 51 (25 and 28 on express mode).',
				'Total Score':'This score will be sent to the leaderboard at the end of the game.',
				'Water':'Water Element Level',
				'Fire':'Fire Element Level',
				'Nature':'Nature Element Level',
				'Earth':'Earth Element Level',
				'Light':'Light Element Level',
				'Dark':'Dark Element Level',
				};

var tooltipsUI = {'Lumber': LumberUI, 'Pure Essence': LumberUI, 'Total Score': ScoreUI,
				  'Water':ElementsUI,'Fire':ElementsUI,
				  'Nature':ElementsUI,'Earth':ElementsUI,
				  'Light':ElementsUI,'Dark':ElementsUI,
				};

var AspectRatio21x9 = false;

function ModifyLumber( data )
{
	var prev = parseInt(lumber.text);
	var diff = data.lumber - prev;
	if (data.lumber != undefined && diff != 0)
	{
		lumber.text = data.lumber;
		/*
		if (diff > 0) {
			lumberDisplay.text = "+" + diff + " Lumber";
			lumberDisplay.visible = true;
			lumberDisplay.AddClass('newResource');
			$.Schedule(3, function(){lumberDisplay.visible = false;lumberDisplay.RemoveClass('newResource');});
		}
		*/
	}
	else
		lumber.text = 0;
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
	tooltip = tooltip.replace(/(['"])/g, "\\$1");
	$.DispatchEvent("DOTAShowTitleTextTooltip", tooltipUI, title, tooltip);
}

//Karawasa Resolution 21x9
function CheckAspectRatio()
{
	var rootHud = LumberUI.GetParent();

	var width = rootHud.actuallayoutwidth;
	var height = rootHud.actuallayoutheight;

	var r = gcd(width, height);

	var ratio = (width/height).toFixed(2);

	// Aspect1:Aspect2
	var Aspect1 = width/r;
	var Aspect2 = height/r;

	var AspectRatio = Aspect1 + ":" + Aspect2;

	$.Msg(AspectRatio);
	
	// 21x9
	if (AspectRatio == "64:27" || AspectRatio == "21:9" || AspectRatio == "43:18")
	{
		AspectRatio21x9 = true;
		rootHud.SetHasClass( "AspectRatio21x9", AspectRatio21x9 );
		$.Msg('Karawasa screen resolution enabled!');
	}
}

function gcd (a, b) {
	return (b == 0) ? a : gcd (b, a%b);
}

(function () {
  $.Schedule(1, function(){  CheckAspectRatio();});
  lumberDisplay.visible = false;
  GameEvents.Subscribe( "etd_update_lumber", ModifyLumber );
  GameEvents.Subscribe( "etd_update_pure_essence", ModifyPureEssence );
  GameEvents.Subscribe( "etd_update_score", ModifyScore );
  GameEvents.Subscribe( "etd_update_elements", UpdateElements );
})();