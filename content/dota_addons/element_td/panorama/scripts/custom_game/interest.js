"use strict";

var INTEREST_INTERVAL = 15;
var INTEREST_RATE = 0.02;

var INTEREST_REFRESH = 0.05;

var interest = $( "#Interest" );
var interestBarGold = $( "#InterestBarGold" );
var tooltipAmount = $( "#TooltipAmount" );

var timerEnd = 0;
var totalGoldEarned = 0;
var enabled = false;
var timerStart = 0;

function UpdateInterest() {
    if (enabled) {
        if ( Game.GetGameTime() > timerEnd ) {
            timerStart = timerEnd;
            timerEnd += INTEREST_INTERVAL;
        }
        var widthPercentage = 100 - Math.floor((timerEnd - Game.GetGameTime())/INTEREST_INTERVAL * 100);
        interestBarGold.style["width"] = widthPercentage+"%";
    }
    $.Schedule(INTEREST_REFRESH, function(){UpdateInterest();});
}

function DisplayInterest( table ) {
    timerStart = Game.GetGameTime();
    timerEnd = Game.GetGameTime() + INTEREST_INTERVAL;
    interest.visible = true;
    enabled = table.enabled;
    INTEREST_INTERVAL = table.interval;
    INTEREST_RATE = table.rate;
}

function InterestEarned( table ) {
    enabled = true;
    interest.visible = true;
    // Sync
    timerStart = Game.GetGameTime();
    timerEnd = timerStart + INTEREST_INTERVAL;
    totalGoldEarned += table.goldEarned;
    tooltipAmount.text = totalGoldEarned;
}

(function () {
  UpdateInterest();
  interest.visible = false;
  GameEvents.Subscribe( "etd_display_interest", DisplayInterest );
  GameEvents.Subscribe( "etd_earned_interest", InterestEarned );
})();