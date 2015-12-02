package 
{
	import flash.events.*;
	import flash.display.*;
	import flash.text.*;
	import fl.controls.*;
	import ValveLib.*;
	import flash.utils.Dictionary;

	public class elements extends MovieClip
	{
		public var gameAPI:Object;
		public var globals:Object;
		public var elementName:String;
		public var titleFormat = new TextFormat();
		
		public var elementTitles:Dictionary = new Dictionary();
		public var elementValues:Dictionary = new Dictionary();
		
		public function elements() 
		{
			collapsedTab.visible = false;
			extendedTab.collapseButton.visible = false;
			extendedTab.collapseButton.stop();
			
			collapsedTab.extendButton.visible = false;
			collapsedTab.extendButton.stop();
			
			createEventListeners();
		}

		public function onLoaded():void
		{
			elementValues["water"] = extendedTab.water;
			elementValues["fire"] = extendedTab.fire;
			elementValues["nature"] = extendedTab.nature;
			elementValues["earth"] = extendedTab.earth;
			elementValues["light"] = extendedTab.light;
			elementValues["dark"] = extendedTab.dark;

			this.gameAPI.SubscribeToGameEvent("etd_update_lumber", this.onLumberUpdate);
			this.gameAPI.SubscribeToGameEvent("etd_update_elements", this.onElementUpdate);

			titleFormat.size = 43;
			titleFormat.bold = "true";
			titleFormat.font = "Dota Hypatia Regular";

			extendedTab.lumberTitle.setTextFormat(titleFormat);
			extendedTab.lumberValue.setTextFormat(titleFormat);
			collapsedTab.lumberTitle.setTextFormat(titleFormat);
			collapsedTab.lumberValue.setTextFormat(titleFormat);
			
			extendedTab.fireTitle.setTextFormat(titleFormat);
			extendedTab.waterTitle.setTextFormat(titleFormat);
			extendedTab.natureTitle.setTextFormat(titleFormat);
			extendedTab.earthTitle.setTextFormat(titleFormat);
			extendedTab.darkTitle.setTextFormat(titleFormat);
			extendedTab.lightTitle.setTextFormat(titleFormat);
			
			for (var element:String in elementValues) {
				elementValues[element].setTextFormat(titleFormat);
			}

			visible = true;
			trace("[HUD] ElementTD Lumber HUD name loaded");
		}

		public function onScreenSizeChanged():void
		{
			scaleX = this.globals.resizeManager.ScreenWidth / 1920 * 0.6;
			scaleY = this.globals.resizeManager.ScreenHeight / 1080 * 0.6;
			x = -5;
			y = (this.globals.resizeManager.ScreenHeight*42)/1080 + 20;
		}

		public function onLumberUpdate(keys:Object)
		{
			if (keys.playerID == globals.Players.GetLocalPlayer())
			{
				extendedTab.lumberValue.text = keys.amount;
				extendedTab.lumberValue.setTextFormat(titleFormat);
				
				collapsedTab.lumberValue.text = keys.amount;
				collapsedTab.lumberValue.setTextFormat(titleFormat);
			}
		}
		
		public function onElementUpdate(keys:Object)
		{
			if (keys.playerID == globals.Players.GetLocalPlayer())
			{
				for (var element in keys) {
					if (elementValues[element] is TextField) {
						elementValues[element].text = keys[element];
						elementValues[element].setTextFormat(titleFormat);
					}
				}
			}
		}
		
		public function createEventListeners()
		{
			var collapseButton = extendedTab.collapseButton;
			var extendButton = collapsedTab.extendButton;
			
			collapseButton.addEventListener(MouseEvent.ROLL_OVER, function():void { 
				collapseButton.gotoAndStop(2); });
			collapseButton.addEventListener(MouseEvent.ROLL_OUT, function():void { 
				collapseButton.gotoAndStop(1); });
			collapseButton.addEventListener(MouseEvent.MOUSE_DOWN, function():void { 
				collapseButton.gotoAndStop(3);});
				
			collapseButton.addEventListener(MouseEvent.MOUSE_UP, function():void { 
				collapseButton.gotoAndStop(2); 
				extendedTab.visible = false;
				collapsedTab.y = extendedTab.y;
				collapsedTab.visible = true;
			});
			extendedTab.addEventListener(MouseEvent.ROLL_OVER, function() : void { 
				collapseButton.visible = true; });
			extendedTab.addEventListener(MouseEvent.ROLL_OUT, function() : void {
				collapseButton.visible = false; });
				
			//==================================================//
			
			extendButton.addEventListener(MouseEvent.ROLL_OVER, function():void { 
				extendButton.gotoAndStop(2); });
			extendButton.addEventListener(MouseEvent.ROLL_OUT, function():void { 
				extendButton.gotoAndStop(1); });
			extendButton.addEventListener(MouseEvent.MOUSE_DOWN, function():void { 
				extendButton.gotoAndStop(3);});
				
			extendButton.addEventListener(MouseEvent.MOUSE_UP, function():void { 
				extendButton.gotoAndStop(2); 
				collapsedTab.visible = false;
				extendedTab.y = collapsedTab.y;
				extendedTab.visible = true;
			});
			collapsedTab.addEventListener(MouseEvent.ROLL_OVER, function() : void { 
				extendButton.visible = true; });
			collapsedTab.addEventListener(MouseEvent.ROLL_OUT, function() : void {
				extendButton.visible = false; });
			
		}
	}
}