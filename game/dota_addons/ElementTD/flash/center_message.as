package 
{
	import flash.events.*;
    import flash.display.*;
	import flash.geom.*;
	import flash.text.*;
	import ValveLib.*;
	import fl.transitions.*;
 	import fl.transitions.easing.*;
	
	public class center_message extends MovieClip {

		public var gameAPI:Object;
        public var globals:Object;
		public var elementName:String;
		
		public var textFormat = new TextFormat();
		
		public var textArea:TextField;
		public var textContainer:MovieClip;
		
		var originalScaleSaved:Boolean = false;
		var originalXScale:Number;
		var originalYScale:Number;
		
		public function center_message()
		{
			textArea.text = "";
			textFormat.font = "Times New Roman";
			textFormat.color = 0xFFFFFF;
		}
		
		public function onLoaded():void
		{
			this.gameAPI.SubscribeToGameEvent("etd_show_message", this.changeText);
			this.gameAPI.SubscribeToGameEvent("etd_warn_message", this.changeWarnText);
			this.globals.resizeManager.AddListener(this);
			visible = false;
        }
		
		public function changeText(keys:Object)
		{
			if (keys.playerID == this.globals.Players.GetLocalPlayer())
			{
				visible = keys.msg != "";;
				textArea.text = keys.msg;
				textArea.setTextFormat(textFormat);
			}
		}
		
		public function changeWarnText(keys:Object)
		{
			if (keys.playerID == this.globals.Players.GetLocalPlayer())
			{
				this.globals.Loader_error_msg.movieClip.setErrorMsg(keys.msg); 
				globals.GameInterface.PlaySound("General.CastFail_AbilityNotLearned");
			}
		}
		
		 public function onResize(re:ResizeManager):* 
		{
            var rm = Globals.instance.resizeManager;
            var currentRatio:Number =  re.ScreenWidth / re.ScreenHeight;
            var divided:Number;

            // Set this to your stage height, however, if your assets are too big/small for 1024x768, you can change it
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
                    
            //You will probably want to scale your elements by here, they keep the same width and height by default.
            //The engine keeps elements at the same X and Y coordinates even after resizing, you will probably want to adjust that here.
			this.resizeTextThing(re.ScreenWidth, re.ScreenHeight, correctedRatio);
        }
		
		public function resizeTextThing(stageW:int, stageH:int, scaleRatio:Number)
		{
			//save this movieClip's original scale
			if(originalScaleSaved == false)
			{
				originalXScale = this.textArea.scaleX;
				originalYScale = this.textArea.scaleY;
				originalScaleSaved = true;
			}
			
			//Let's say we want our element to scale proportional to the screen height, scale like this:
			this.textArea.scaleX = originalXScale * scaleRatio;
			this.textArea.scaleY = originalYScale * scaleRatio;
			
			// calculate the top bar (portraits and killcounts) and bottom (abilities) bar heights
			var topBarHeight = (64 * stageW) / 2560;
			var bottomBarHeight = (290 * stageW) / 2560;
			
			var posx:int = (stageW / 2) - (this.textArea.width / 2);
			var posy:int = topBarHeight * 1.5;
			
			this.textArea.x = posx;
			this.textArea.y = posy;
		}
	}
}