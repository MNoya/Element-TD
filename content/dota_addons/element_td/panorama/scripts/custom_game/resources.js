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
				'Pure Essence':'You can buy Pure Essences from the summoner for 1 lumber.<br>You will recieve 1 pure essence on wave 46 and 51 (25 and 28 on express mode).',
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

(function () {
  lumberDisplay.visible = false;
  GameEvents.Subscribe( "etd_update_lumber", ModifyLumber );
  GameEvents.Subscribe( "etd_update_pure_essence", ModifyPureEssence );
  GameEvents.Subscribe( "etd_update_score", ModifyScore );
  GameEvents.Subscribe( "etd_update_elements", UpdateElements );
})();