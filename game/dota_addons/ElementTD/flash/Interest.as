package  
{
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import scaleform.clik.events.*;
	
    import ValveLib.Globals;
    import ValveLib.ResizeManager;
	import flash.utils.getDefinitionByName;
	import flash.utils.*;
	import flash.events.TimerEvent;
	
	public class Interest extends MovieClip
	{
		// element details filled out by game engine
		public var gameAPI:Object;
		public var globals:Object;
		public var elementName:String;
		
		var originalScaleSaved:Boolean = false;
		var originalXScale:Number;
		var originalYScale:Number;
		
		var ticksPerSecond:Number = 10;
		var maxWidth:Number;
		var timerDuration:Number;
		var baseX:Number;
		var totalGoldEarned:Number = 0;
		
		public function Interest() {}
		
		public function onLoaded():void
		{
			this.visible = false;
			this.interestElement.visible = true;
			this.interestElement.tooltipMC.visible = false;
			
            this.globals.resizeManager.AddListener(this);
			
			this.interestElement.goldBar.visible = true;
			this.maxWidth = this.interestElement.goldBar.width;
			this.baseX = this.interestElement.goldBar.x;
			
			this.interestElement.interestText.addEventListener(MouseEvent.ROLL_OVER, this.ShowTooltip);
			this.interestElement.interestText.addEventListener(MouseEvent.ROLL_OUT, this.HideTooltip);
					
			this.gameAPI.SubscribeToGameEvent("etd_start_interest_timer", this.StartInterestTimer);
			this.gameAPI.SubscribeToGameEvent("etd_interest_earned", this.OnInterestEarned);
			trace("Interest loaded");
		}
		
		public function OnInterestEarned(args:Object)
		{
			this.totalGoldEarned += args["player" + globals.Players.GetLocalPlayer());
			trace("Total gold earned: " + this.totalGoldEarned);
		}
		
		public function StartInterestTimer(args:Object)
		{
			if (!this.visible) {
				this.visible = true;
			}
			this.timerDuration = args.duration;
			this.interestElement.goldBar.width = 0;
			
			var timer:Timer = new Timer(1000 / this.ticksPerSecond, this.ticksPerSecond * this.timerDuration);
			timer.addEventListener(TimerEvent.TIMER, this.OnInterestThink);
			timer.start();
		}
		
		public function OnInterestThink()
		{
			var pixelsPerTick = this.maxWidth / (this.ticksPerSecond * this.timerDuration);
			this.interestElement.goldBar.width += pixelsPerTick;
			this.interestElement.goldBar.x = (this.maxWidth - this.interestElement.goldBar.width) / -2;
		}
		
		public function ShowTooltip():void
		{
			 this.interestElement.tooltipMC.visible = true;
		}
		public function HideTooltip():void
		{
			 this.interestElement.tooltipMC.visible = false;
		}
		
        public function onResize(re:ResizeManager):* 
		{
            var rm = Globals.instance.resizeManager;
            var currentRatio:Number =  re.ScreenWidth / re.ScreenHeight;
            var divided:Number;

            var originalHeight:Number = 900;
                    
            if(currentRatio < 1.5)
            {
                // 4:3
                divided = currentRatio / 1.333;
            }
            else if(re.Is16by9()){
                // 16:9
                divided = currentRatio / 1.7778;
            } else {
                // 16:10
                divided = currentRatio / 1.6;
            }
                    
            var correctedRatio:Number =  re.ScreenHeight / originalHeight * divided;
			var topBarHeight = (64 * re.ScreenWidth) / 2560;
			var bottomBarHeight = (290 * re.ScreenWidth) / 2560;
			
			if(originalScaleSaved == false)
			{
				originalXScale = this.scaleX;
				originalYScale = this.scaleY;
				originalScaleSaved = true;
			}
			
			//Let's say we want our element to scale proportional to the screen height, scale like this:
			this.interestElement.scaleX = originalXScale * correctedRatio;
			this.interestElement.scaleY = originalYScale * correctedRatio;
			
			var posx:int = re.ScreenWidth - (this.interestElement.width / 2) - (10 * this.interestElement.scaleX);
			var posy:int = (topBarHeight / 2);
			
			if (currentRatio < 1.5) {
				posy+=3;
			}
			else if(re.Is16by9()) {
				posy-=2;
			}
			
			this.interestElement.x = posx;
			this.interestElement.y = posy;
        }
	}
}
