package {
	import flash.display.MovieClip;

	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;
	import scaleform.clik.events.*;
	import flash.utils.*;
	import flash.events.TimerEvent;
	
	public class etd extends MovieClip
	{
		
		//these three variables are required by the engine
		public var gameAPI:Object;
		public var globals:Object;
		public var elementName:String;
		public var oldAbilityClickedFunction:Function;
		
		public var idToAbilityMap:Dictionary = new Dictionary();
		public var abilitySelectedMap:Dictionary = new Dictionary();
		
		//unused constructor
		public function etd() : void {}
		
		//this function is called when the UI is loaded
		public function onLoaded() : void 
		{			
			this.globals.GameInterface.SetConvar("scaleform_spew", "1");
			this.gameAPI.SubscribeToGameEvent("etd_game_started", this.onGameStart);
			this.globals.resizeManager.AddListener(this);
			trace("ElementTD UI loaded!");
			
			this.oldAbilityClickedFunction = this.globals.Loader_actionpanel.gameAPI.OnAbilityClicked;
			this.globals.Loader_actionpanel.gameAPI.OnAbilityClicked = this.OnAbilityClicked;
			
			this.globals.Loader_inventory.movieClip.inventory.glyphButton.visible = false; //disable glyph button
			this.globals.Loader_inventory.movieClip.inventory.shopbutton.visible = false; //disable shop button
			this.globals.Loader_inventory.movieClip.inventory.quickbuy.visible = false; //disable quickbuy
			this.globals.Loader_inventory.movieClip.inventory.courierState.visible = false; //disable courier ui
			this.globals.Loader_inventory.movieClip.inventory.quickstats.visible = false;
			this.globals.Loader_inventory.movieClip.inventory.actionItem.visible = false; //disable action items
			
			var quickstats:MovieClip = this.globals.Loader_inventory.movieClip.inventory.quickstats;

			while (quickstats.numChildren > 0) {
    			quickstats.removeChildAt(0);
			}
			
			while (this.globals.Loader_quickstats.movieClip.quickstats.numChildren > 0) {
    			this.globals.Loader_quickstats.movieClip.quickstats.removeChildAt(0);
			}
			
			var timer:Timer = new Timer(100, 0);
			timer.addEventListener(TimerEvent.TIMER, this.timerListener);
			timer.start();
			
		}
		
		public function OnAbilityClicked(spellIndex:int, buttonIndex:int)
		{
			this.oldAbilityClickedFunction(spellIndex, buttonIndex);
		}
		
		public function timerListener(e:TimerEvent)
		{
			var selectedUnit = globals.Loader_actionpanel.movieClip.middle.unitName.text;
			var anyAbilityPressed:Boolean = false;
			
			for (var id:String in idToAbilityMap)
			{
				var abilityButton = idToAbilityMap[id];
				if (abilityButton.activePressedType.visible) {
					anyAbilityPressed = true;
				}
				
				if (abilityButton.activePressedType.visible && abilitySelectedMap[id] == false && selectedUnit == "Builder") {
					//trace("Ability " + id + " has been pressed down");
					this.gameAPI.SendServerCommand("etd_ability_selected " + id);
				}
				else if(!abilityButton.activePressedType.visible && abilitySelectedMap[id] == true && selectedUnit == "Builder") {
					//trace("Ability " + id + " has been released");
					this.gameAPI.SendServerCommand("etd_ability_deselected " + id);
				}
				abilitySelectedMap[id] = abilityButton.activePressedType.visible;
			}
			
			if (anyAbilityPressed) {
				var worldPos = this.globals.Game.ScreenXYToWorld(this.stage.mouseX, this.stage.mouseY);
				this.gameAPI.SendServerCommand("etd_update_pos " + worldPos[0] + " " + worldPos[1] + " " + worldPos[2]);
			}
		}
		
		public function onGameStart(args:Object) 
		{
			var abilities:MovieClip = this.globals.Loader_actionpanel.movieClip.middle.abilities;
			idToAbilityMap["0"] = abilities.Ability0;
			idToAbilityMap["1"] = abilities.Ability1;
			idToAbilityMap["2"] = abilities.Ability2;
			idToAbilityMap["3"] = abilities.Ability3;
			idToAbilityMap["4"] = abilities.Ability4;
			
			abilitySelectedMap["0"] = false;
			abilitySelectedMap["1"] = false;
			abilitySelectedMap["2"] = false;
			abilitySelectedMap["3"] = false;
			abilitySelectedMap["4"] = false;
			
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
        }
		
		public function strRep(str, count) {
            var output = "";
            for(var i=0; i<count; i++) {
                output = output + str;
            }

            return output;
        }

        public function isPrintable(t) {
        	if(t == null || t is Number || t is String || t is Boolean || t is Function || t is Array) {
        		return true;
        	}
        	// Check for vectors
        	if(flash.utils.getQualifiedClassName(t).indexOf('__AS3__.vec::Vector') == 0) return true;

        	return false;
        }

        public function PrintTable(t, indent=0, done=null) {
        	var i:int, key, key1, v:*;

        	// Validate input
        	if(isPrintable(t)) {
        		trace("PrintTable called with incorrect arguments!");
        		return;
        	}

        	if(indent == 0) {
        		trace(t.name+" "+t+": {")
        	}

        	// Stop loops
        	done ||= new flash.utils.Dictionary(true);
        	if(done[t]) {
        		trace(strRep("\t", indent)+"<loop object> "+t);
        		return;
        	}
        	done[t] = true;

        	// Grab this class
        	var thisClass = flash.utils.getQualifiedClassName(t);

        	// Print methods
			for each(key1 in flash.utils.describeType(t)..method) {
				// Check if this is part of our class
				if(key1.@declaredBy == thisClass) {
					// Yes, log it
					trace(strRep("\t", indent+1)+key1.@name+"()");
				}
			}

			// Check for text
			if("text" in t) {
				trace(strRep("\t", indent+1)+"text: "+t.text);
			}

			// Print variables
			for each(key1 in flash.utils.describeType(t)..variable) {
				key = key1.@name;
				v = t[key];

				// Check if we can print it in one line
				if(isPrintable(v)) {
					trace(strRep("\t", indent+1)+key+": "+v);
				} else {
					// Open bracket
					trace(strRep("\t", indent+1)+key+": {");

					// Recurse!
					PrintTable(v, indent+1, done)

					// Close bracket
					trace(strRep("\t", indent+1)+"}");
				}
			}

			// Find other keys
			for(key in t) {
				v = t[key];

				// Check if we can print it in one line
				if(isPrintable(v)) {
					trace(strRep("\t", indent+1)+key+": "+v);
				} else {
					// Open bracket
					trace(strRep("\t", indent+1)+key+": {");

					// Recurse!
					PrintTable(v, indent+1, done)

					// Close bracket
					trace(strRep("\t", indent+1)+"}");
				}
        	}

        	// Get children
        	if(t is MovieClip) {
        		// Loop over children
	        	for(i = 0; i < t.numChildren; i++) {
	        		// Open bracket
					trace(strRep("\t", indent+1)+t.name+" "+t+": {");

					// Recurse!
	        		PrintTable(t.getChildAt(i), indent+1, done);

	        		// Close bracket
					trace(strRep("\t", indent+1)+"}");
	        	}
        	}

        	// Close bracket
        	if(indent == 0) {
        		trace("}");
        	}
        }
		
		
	}
}