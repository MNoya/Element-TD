package  
{
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.utils.getDefinitionByName;
	import scaleform.clik.events.*;
	import flash.text.TextFormat;
	import scaleform.clik.interfaces.IDataProvider;
    import scaleform.clik.data.DataProvider;
    import flash.media.Video;
	import com.adobe.serialization.json.JSON;
	
	public class VoteDialog extends MovieClip 
	{
		var formatText:TextFormat = new TextFormat();
		var formatTitle:TextFormat = new TextFormat();
		
		//hold the gameAPI
    	var gameAPI:Object;
		var globals:Object;
		
		var originalScaleSaved:Boolean = false;
		var originalXScale:Number;
		var originalYScale:Number;
		
		var gamemodeComboBox:MovieClip;
		var difficultyComboBox:MovieClip;
		var elementsComboBox:MovieClip;
		var orderComboBox:MovieClip;
		var lengthComboBox:MovieClip;
		var confirmButton:MovieClip;
	
		var gameModes:Array = new Array();
		var difficultyModes:Array = new Array();
		var elementModes:Array = new Array();
		var orderModes:Array = new Array();
		var lengthModes:Array = new Array();
		
		public function VoteDialog() 
		{
		}
		
		public function setup(api:Object, gbls:Object) 
		{
        	this.gameAPI = api;
			this.globals = gbls;
			this.formatText.font = "$TextFont";
			this.formatTitle.font = "$TitleFont";
			
			lblWaitingForOthers.visible = false;
			
			var bg = Voting.replaceWithValveComponent(bgPH, "bg_overlayBox", true);
			bg.x -= bg.width / 2;
			bg.y -= bg.height / 2;
			bg.parent.setChildIndex (bg, 0);
			
			confirmButton = Voting.replaceWithValveComponent(confirmButtonPH, "chrome_button_normal", true);
			confirmButton.x = confirmButton.x - 0.1 * confirmButton.width;
			confirmButton.label = "CONFIRM VOTE";
			confirmButton.addEventListener(ButtonEvent.PRESS, this.ConfirmVote);
			
			this.gameAPI.SubscribeToGameEvent("etd_update_vote_timer", this.UpdateVoteTimer);
			populateComboBoxes();
    	}
		
		public function UpdateVoteTimer(args:Object)
		{
			lblTimeRemaining.text = args.time;
		}
			
		public function ConfirmVote()
		{
			confirmButton.visible = false;
			lblWaitingForOthers.visible = true;
			
			var dataObject:Object = new Object();
			dataObject["playerID"] = globals.Players.GetLocalPlayer();
			dataObject["gamemodeVote"] = gameModes[gamemodeComboBox.selectedIndex];
			dataObject["difficultyVote"] = difficultyModes[difficultyComboBox.selectedIndex];
			dataObject["elementsVote"] = elementModes[elementsComboBox.selectedIndex];
			dataObject["orderVote"] = orderModes[orderComboBox.selectedIndex];
			dataObject["lengthVote"] = lengthModes[lengthComboBox.selectedIndex];
			
			gamemodeComboBox.enabled = false;
			difficultyComboBox.enabled = false;
			elementsComboBox.enabled = false;
			orderComboBox.enabled = false;
			lengthComboBox.enabled = false;
			
			var voteData = com.adobe.serialization.json.JSON.encode(dataObject);
			voteData = Base64.encode(voteData);

			this.gameAPI.SendServerCommand("etd_player_voted " + voteData);
		}
		
		public function populateComboBoxes()
		{
			var gamesettingsKV = globals.GameInterface.LoadKVFile("scripts/kv/gamesettings.kv");
	
			//=Gamemodes Dropdown================================================================//
			var gamemodeData:Array = new Array(); 
			for (var gm in gamesettingsKV.GameModes) {
				var gamemode = gamesettingsKV.GameModes[gm];
				gamemodeData[int(gamemode.Index)] = {label:gamemode.Name, data:gamemode.Description};
				gameModes[int(gamemode.Index)] = gm;
			}
			
			gamemodeComboBox = comboBox(this, new DataProvider(gamemodeData), gamemodeComboPH);
			gamemodeComboBox.setSelectedIndex(0);
			
			gamemodeDesc.text = gamemodeComboBox.menuList.dataProvider[0].data;
			
			gamemodeComboBox.setIndexCallback = function():void {
				gamemodeDesc.text = gamemodeComboBox.menuList.dataProvider[gamemodeComboBox.selectedIndex].data;
			};

			//=================================================================//

			//=Difficulty Dropdown=================================================================//
			var difficultyData:Array = new Array(); 
			for (var df in gamesettingsKV.Difficulty) {
				var difficulty = gamesettingsKV.Difficulty[df];
				difficultyData[int(difficulty.Index)] = {label:difficulty.Name, data:
					(parseFloat(difficulty.Health) * 1000) / 10 + "% Creep Health, " + int(parseFloat(difficulty.Armor) * 100) + "% Creep Armor, " + int(difficulty.BaseBounty * 1000)/1000+ " Base Bounty"
				};
				difficultyModes[int(difficulty.Index)] = df;
			}
			difficultyComboBox = comboBox(this, new DataProvider(difficultyData), difficultyComboPH);
			difficultyComboBox.setSelectedIndex(2); //default difficulty is Normal
			
			difficultyDesc.text = difficultyComboBox.menuList.dataProvider[0].data;
			difficultyDesc.setTextFormat(formatText);
			
			difficultyComboBox.setIndexCallback = function():void {
				difficultyDesc.text = difficultyComboBox.menuList.dataProvider[difficultyComboBox.selectedIndex].data;
			};

			
			//=Elements Dropdown================================================================//
			var elementsData:Array = new Array(); 
			for (var ele in gamesettingsKV.ElementModes) {
				var elementMode = gamesettingsKV.ElementModes[ele];
				elementsData[int(elementMode.Index)] = {label:elementMode.Name, data:elementMode.Description};
				elementModes[int(elementMode.Index)] = ele;
			}
			elementsComboBox = comboBox(this, new DataProvider(elementsData), elementsComboPH);
			elementsComboBox.setSelectedIndex(0); 
			
			elementsDesc.text = elementsComboBox.menuList.dataProvider[0].data;
			elementsDesc.setTextFormat(formatText);
			
			elementsComboBox.setIndexCallback = function():void {
				elementsDesc.text = elementsComboBox.menuList.dataProvider[elementsComboBox.selectedIndex].data;
			};
			
			
			//=Order Dropdown================================================================//
			var orderData:Array = new Array();
			for (var orderName in gamesettingsKV.CreepOrder) {
				var order = gamesettingsKV.CreepOrder[orderName];
				orderData[int(order.Index)] = {label:order.Name, data:order.Description};
				orderModes[int(order.Index)] = orderName;
			}

			orderComboBox = comboBox(this, new DataProvider(orderData), orderComboPH);
			orderComboBox.setSelectedIndex(0); 
			
			orderDesc.text = orderComboBox.menuList.dataProvider[0].data;
			orderDesc.setTextFormat(formatText);
			
			orderComboBox.setIndexCallback = function():void {
				orderDesc.text = orderComboBox.menuList.dataProvider[orderComboBox.selectedIndex].data;
			};
			
			
			//=Game Length===============================================================//
			var lengthData:Array = new Array();
			for (var lnth in gamesettingsKV.GameLength) {
				var gameLength = gamesettingsKV.GameLength[lnth];
				lengthData[int(gameLength.Index)] = {label:gameLength.Name, 
					data:"Start at wave " + gameLength.Wave + " with " + gameLength.Gold + " Gold and " + gameLength.Lumber + " Lumber."
				};
				lengthModes[int(gameLength.Index)] = lnth;
			}

			lengthComboBox = comboBox(this, new DataProvider(lengthData), lengthComboPH);
			lengthComboBox.setSelectedIndex(0); 
			
			lengthDesc.text = lengthComboBox.menuList.dataProvider[0].data;
			lengthDesc.setTextFormat(formatText);
			
			lengthComboBox.setIndexCallback = function():void {
				lengthDesc.text = lengthComboBox.menuList.dataProvider[lengthComboBox.selectedIndex].data;
			};
		}
		
		//we define a public function, because we call it from outside our module object.
		//we get four parameters, the stage's dimensions and the scale ratios. Flash does not have floats, we use Number for that.
		//you might wonder what happened to the ': void'. Whenever that is not added, void is assumed
		public function screenResize(stageW:int, stageH:int, scaleRatio:Number)
		{
			// calculate the top bar (portraits and killcounts) and bottom (abilities) bar heights
			var topBarHeight = (64 * stageW) / 2560;
			var bottomBarHeight = (290 * stageW) / 2560;
			
			var posx:int = stageW / 2;
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
		
		 public static function comboBox(container:MovieClip, dp:DataProvider, base:MovieClip):MovieClip 
		 {
            var dotoComboBoxClass:Class = getDefinitionByName("ComboBoxSkinned") as Class;
            var comboBox:MovieClip = new dotoComboBoxClass();
            container.addChild(comboBox);
            comboBox.setDataProvider(dp);
			
			comboBox.x = base.x - (base.width / 2);
			comboBox.y = base.y - (base.height / 2);
			base.parent.removeChild(base);
			
            return comboBox;
        }
		
		function replace(str:String, fnd:String, rpl:String):String
		{
			return str.split(fnd).join(rpl);
		}
	}
}