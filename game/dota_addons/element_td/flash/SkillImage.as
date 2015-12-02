package  {
	
	import flash.display.MovieClip;
	import ValveLib.Globals;
	import flash.events.MouseEvent;
    import flash.geom.Point;
	
	public class SkillImage extends MovieClip 
	{
		public var imageHolder:MovieClip;
		public var skillName:String;
		public var abilitiesKV;
		
		public function SkillImage()
		{
			imageHolder = new MovieClip();
			imageHolder.scaleX = 0.21875;
			imageHolder.scaleY = 0.21875;
						
			this.x -= (this.width / 2);
			this.y -= (this.height / 2);
			
            this.addChild(imageHolder);
			this.removeChild(this.placeholder);
			this.addEventListener(MouseEvent.ROLL_OVER, this.onMouseRollOver, false, 0, true);
			this.addEventListener(MouseEvent.ROLL_OUT, this.onMouseRollOut, false, 0, true);
			
			this.abilitiesKV = Globals.instance.GameInterface.LoadKVFile("scripts/npc/npc_abilities_custom.txt");
		}

		public function setSkill(skillName:String) 
		{
			if(skillName != "") 
			{
				this.visible = true;
				var abilityTextureName:String;
				
				if (this.abilitiesKV[skillName] != null && this.abilitiesKV[skillName] != "") {
					abilityTextureName = this.abilitiesKV[skillName].AbilityTextureName;
				}
				else {
					abilityTextureName = "unknown";
				}
				this.skillName = skillName;
				Globals.instance.LoadAbilityImage(abilityTextureName, this.imageHolder);
			}
			else {
				this.visible = false;
			}
		}
		
		public function onMouseRollOver()
		{
			var lp:Point = this.localToGlobal(new Point(0, 0));
			Globals.instance.Loader_heroselection.gameAPI.OnSkillRollOver(lp.x, lp.y, this.skillName);
		}
		
		public function onMouseRollOut()
		{
			Globals.instance.Loader_heroselection.gameAPI.OnSkillRollOut();
		}
		
	}
}