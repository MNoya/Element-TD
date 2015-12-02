package  
{
	import flash.display.MovieClip;
	
	public class InterestOverlay extends MovieClip 
	{
		var gameAPI:Object;
		var globals:Object;
		
		var originalScaleSaved:Boolean = false;
		var originalXScale:Number;
		var originalYScale:Number;
		
		public function InterestOverlay() 
		{
		}
		
		public function setup(api:Object, gbls:Object) 
		{
        	this.gameAPI = api;
			this.globals = gbls;
    	}
		
		public function screenResize(stageW:int, stageH:int, scaleRatio:Number)
		{
			if(originalScaleSaved == false)
			{
				originalXScale = this.scaleX;
				originalYScale = this.scaleY;
				originalScaleSaved = true;
			}
			
			this.scaleX = originalXScale * scaleRatio;
			this.scaleY = originalYScale * scaleRatio;
		
			// calculate the top bar (portraits and killcounts) and bottom (abilities) bar heights
			var topBarHeight = (64 * stageW) / 2560;
			var bottomBarHeight = (290 * stageW) / 2560;
			
			var posx:int = stageW - (this.width / 2 * this.scaleX);
			var posy:int = (stageH - bottomBarHeight / 2);
			
			this.x = posx;
			this.y = posy;
		}
	}
}