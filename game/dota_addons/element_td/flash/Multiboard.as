package  
{
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import scaleform.clik.events.*;
	
	//import some stuff from the valve lib
    import ValveLib.Globals;
    import ValveLib.ResizeManager;
	import flash.utils.getDefinitionByName;
	
	public class Multiboard extends MovieClip
	{
		// element details filled out by game engine
		public var gameAPI:Object;
		public var globals:Object;
		public var elementName:String;
		
		public function Multiboard(){}
		
		// called by the game engine when this .swf has finished loading
		public function onLoaded():void
		{
			this.visible = true;
			this.waveInfoDialog.visible = true;
            this.globals.resizeManager.AddListener(this);
			
			this.waveInfoDialog.setup(this.gameAPI, this.globals);
			trace("Scoreboard loaded");
		}
		
		//this handles the resizes, it sets the UI dimensions to your screen dimensions, credits to Nullscope
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
			this.waveInfoDialog.screenResize(re.ScreenWidth, re.ScreenHeight, correctedRatio);
        }
		
		//Parameters: 
		//mc - The movieclip to replace
    	//type - The name of the class you want to replace with
    	//keepDimensions - Resize from default dimensions to the dimensions of mc (optional, false by default)
		public static function replaceWithValveComponent(mc:MovieClip, type:String, keepDimensions:Boolean = false) : MovieClip
		{
			var parent = mc.parent;
			var oldx = mc.x;
			var oldy = mc.y;
			var oldwidth = mc.width;
			var oldheight = mc.height;
		
			var newObjectClass = getDefinitionByName(type);
			var newObject = new newObjectClass();
			newObject.x = oldx;
			newObject.y = oldy;
			if (keepDimensions) 
			{
				newObject.width = oldwidth;
				newObject.height = oldheight;
			}
		
			parent.removeChild(mc);
			parent.addChild(newObject);
		
			return newObject;
		}
	}
}
