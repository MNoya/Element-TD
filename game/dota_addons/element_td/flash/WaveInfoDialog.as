package  {
	import flash.display.MovieClip;
	import flash.utils.*;
	import flash.events.TimerEvent;
	
	public class WaveInfoDialog extends MovieClip 
	{
		var gameAPI:Object;
		var globals:Object;
		
		var originalScaleSaved:Boolean = false;
		var originalXScale:Number;
		var originalYScale:Number;
		
		var timeRemaining:Number;
		var creepKV;
		
		public function WaveInfoDialog() 
		{
		}
		
		public function setup(api:Object, gbls:Object) 
		{
			this.visible = false;
        	this.gameAPI = api;
			this.globals = gbls;
			
			var bg = Multiboard.replaceWithValveComponent(bgPH, "bg_overlayBox", true);
			bg.x -= bg.width / 2;
			bg.y -= bg.height / 2;
			bg.parent.setChildIndex(bg, 0);
			
			this.gameAPI.SubscribeToGameEvent("etd_update_wave_info", this.UpdateWaveInfo);
			this.gameAPI.SubscribeToGameEvent("etd_update_wave_timer", this.UpdateWaveTimer);
			
			this.currentWaveElement.setSkill("");
			this.currentWaveAbility.setSkill("");
			this.nextWaveElement.setSkill("");
			this.nextWaveAbility.setSkill("");
			
			this.nextWave.text = "";
			this.currentWave.text = "";
			
			this.creepKV = this.globals.GameInterface.LoadKVFile("scripts/npc/npc_units_custom.txt");
    	}
		
		public function UpdateWaveInfo(args:Object)
		{
			if (args.playerID == globals.Players.GetLocalPlayer()) {
				if (!this.nextWave.text == "") {
					this.currentWave.text = this.nextWave.text;
					this.currentWaveElement.setSkill(this.nextWaveElement.skillName);
					if (this.nextWaveAbility.visible == true) {
						this.currentWaveAbility.setSkill(this.nextWaveAbility.skillName);
					}
					else {
						this.currentWaveAbility.setSkill("");
					}
				}
			
				this.nextWave.text = "Wave " + args.nextWave;
				this.nextWaveElement.setSkill(this.creepKV[args.nextWaveCreep].Ability1);
				if (this.creepKV[args.nextWaveCreep].Ability2) {
					this.nextWaveAbility.setSkill(this.creepKV[args.nextWaveCreep].Ability2);
				}
				else {
					this.nextWaveAbility.setSkill("");
				}
			}
		}
		
		public function UpdateWaveTimer(args:Object)
		{
			this.visible = true;
			if (args.playerID == globals.Players.GetLocalPlayer()) {
				this.timeRemaining = args.time;
				this.nextWaveTimer.text = (this.timeRemaining + "");
				var timer:Timer = new Timer(1000, args.time);
				timer.addEventListener(TimerEvent.TIMER, this.OnTimerThink);
				timer.start();
			}
		}
		
		public function OnTimerThink()
		{
			this.timeRemaining--;
			this.nextWaveTimer.text = (this.timeRemaining + "");
			if (this.timeRemaining == 0) {
				this.nextWaveTimer.text = "";
			}
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
			
			var topBarHeight = (64 * stageW) / 2560;
			var bottomBarHeight = (290 * stageW) / 2560;
			
			var posx:int = stageW - (this.width / 2) - 10;
			var posy:int = topBarHeight + (this.height / 2) + 10;
			
			this.x = posx;
			this.y = posy;
		}
		
		
	}
}