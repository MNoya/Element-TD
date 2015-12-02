package  {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.utils.getDefinitionByName;
	import scaleform.clik.events.*;
	import flash.text.TextFormat;
	import scaleform.clik.interfaces.IDataProvider;
    import scaleform.clik.data.DataProvider;
    import flash.media.Video;
	
	public class VoteResultsDialog extends MovieClip 
	{
		var gameAPI:Object;
		var globals:Object;
		var okButton:MovieClip;
		
		var originalScaleSaved:Boolean = false;
		var originalXScale:Number;
		var originalYScale:Number;
		
		public function VoteResultsDialog() 
		{

		}
		
		public function setup(api:Object, gbls:Object) 
		{
			this.visible = false;
        	this.gameAPI = api;
			this.globals = gbls;
			
			var bg = Voting.replaceWithValveComponent(bgPH, "bg_overlayBox", true);
			bg.x -= bg.width / 2;
			bg.y -= bg.height / 2;
			bg.parent.setChildIndex(bg, 0);
			
			okButton = Voting.replaceWithValveComponent(okButtonPH, "chrome_button_normal", true);
			okButton.x = okButton.x - 0.1 * okButton.width;
			okButton.label = "OK";
			okButton.addEventListener(ButtonEvent.PRESS, this.OKButtonPressed);
			
			this.gameAPI.SubscribeToGameEvent("etd_vote_results", this.ShowVoteResults);
    	}
		
		public function ShowVoteResults(args:Object)
		{
			if (args.playerID == this.globals.Players.GetLocalPlayer()) {
				this.visible = true;
				
				var gamesettingsKV = this.globals.GameInterface.LoadKVFile("scripts/kv/gamesettings.kv");
				
				gamemodeResult.text = gamesettingsKV.GameModes[args.gamemode].Name;
				difficultyResult.text = gamesettingsKV.Difficulty[args.difficulty].Name;
				elementsResult.text =gamesettingsKV.ElementModes[args.elements].Name;
				orderResult.text = args.order;
				lengthResult.text = gamesettingsKV.GameLength[args.length].Name;
			}
		}
		
		public function OKButtonPressed()
		{
			this.visible = false;
		}
		
		public function screenResize(stageW:int, stageH:int, scaleRatio:Number)
		{
			// calculate the top bar (portraits and killcounts) and bottom (abilities) bar heights
			var topBarHeight = (64 * stageW) / 2560;
			var bottomBarHeight = (290 * stageW) / 2560;
			
			var posx:int = (stageW / 2);
			var posy:int = ((stageH - bottomBarHeight) / 2) + topBarHeight;
			
			//we set the position of this movieclip to the center of the stage
			//remember, the black cross in the center is our center. You control the alignment with this code, you can align your module however you like.
			this.x = posx;
			this.y = posy;
			//A small example of aligning to the right bottom corner would be:
			/* this.x = StageW - xScale*this.width/2;
			 * this.y = StageH - yScale*this.height/2; */
			
			//save this movieClip's original scale
			if(originalScaleSaved == false)
			{
				originalXScale = this.scaleX;
				originalYScale = this.scaleY;
				originalScaleSaved = true;
			}
			
			//Let's say we want our element to scale proportional to the screen height, scale like this:
			this.scaleX = originalXScale * scaleRatio;
			this.scaleY = originalYScale * scaleRatio;
		}
	}
}
