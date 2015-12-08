"use strict";

var elementUI = $( "#Elements" );
var button = $( "#ElementButton" );
var button2 = $( "#ElementButton2" );
var secondary = $( '#Secondary' );

var lumber = $( '#LumberValue' );

var lumberDisplay = $( '#LumberDisplay' );

var elements = {water: '#WaterValue', fire: '#FireValue', nature: '#NatureValue', earth: '#EarthValue', light: '#LightValue', dark:'#DarkValue'};

var toggle = true; // True = Visible, false = collapsed

function ModifyLumber( data )
{
    var prev = parseInt(lumber.text);
    var diff = data.lumber - prev;
    if (data.lumber != undefined && diff != 0)
    {
        lumber.text = data.lumber;
        if (diff > 0) {
            lumberDisplay.text = "+" + diff + " Lumber";
            lumberDisplay.visible = true;
            lumberDisplay.AddClass('newResource');
            $.Schedule(3, function(){lumberDisplay.visible = false;lumberDisplay.RemoveClass('newResource');});
        }
    }
    else
        lumber.text = 0;
}

function UpdateElements( data )
{
    for(var element in data)
    {
        if( element in elements )
        {
            $(elements[element]).text = data[element];
        }
    }
}

function ShowButton()
{
    if(toggle)
        button.visible = true;
    else
        button2.visible = true;
}

function HideButton()
{
    if(toggle)
        button.visible = false;
    else
        button2.visible = false;
}

function ToggleCollapse()
{
    toggle = !toggle;
    Game.EmitSound("ui_generic_button_click");
    if (toggle)
    {
        button2.visible = false;
        button.visible = true;
        secondary.visible = true;
        elementUI.RemoveClass('small');
    }
    else
    {
        button2.visible = true;
        button.visible = false;
        secondary.visible = false;
        elementUI.AddClass('small');
    }
}

(function () {
  button.visible = false;
  button2.visible = false;
  lumberDisplay.visible = false;
  GameEvents.Subscribe( "etd_update_lumber", ModifyLumber );
  GameEvents.Subscribe( "etd_update_elements", UpdateElements );
})();