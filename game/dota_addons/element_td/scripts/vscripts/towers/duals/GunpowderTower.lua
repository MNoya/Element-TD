-- Gunpowder Tower class (Dark + Earth)
-- This is a long range tower that shoots a projectile which does splash damage. Upon exploding the projectile creates three more that scatter randomly around the impact point. 
-- You can think of this sort of like a cluster grenade.

GunpowderTower = createClass({
		tower = nil,
		towerClass = "",

		constructor = function(self, tower, towerClass)
            self.tower = tower;
            self.towerClass = towerClass or self.towerClass;
        end
	},
	{
		className = "GunpowderTower";
	},
nil);

function GunpowderTower:OnAttackLanded(keys) 
    local target = keys.target;
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_supernova_reborn_star_sphere.vpcf", PATTACH_CUSTOMORIGIN, self.tower);
    ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin());
      
    local damage = ApplyAbilityDamageFromModifiers(self.splashDamage[self.tower:GetLevel()], self.tower);
    DamageEntitiesInArea(target:GetOrigin(), self.splashAOE, self.tower, damage)

      --spawn random explosions around the initial point
      for i = 1, 3, 1 do
        CreateTimer("CreateExplosion" .. self.tower:entindex() .. i, DURATION, {
          duration = RandomFloat(0.15, 0.50),
          pos = RandomPositionInCircle(target:GetAbsOrigin(), 300),
          callback = function(timer)
              
              local p = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_supernova_reborn_star_sphere.vpcf", PATTACH_CUSTOMORIGIN, self.tower);
              ParticleManager:SetParticleControl(p, 0, timer.pos);

              if IsValidEntity(self.tower) then
                local damage = ApplyAbilityDamageFromModifiers(self.splashDamage[self.tower:GetLevel()], self.tower);
                DamageEntitiesInArea(timer.pos, self.splashAOE, self.tower, damage);
              end
      
          end
        });
      end
end

function GunpowderTower:OnCreated()
  self.ability = AddAbility(self.tower, "gunpowder_tower_shrapnade", self.tower:GetLevel()); 
  self.splashDamage = GetAbilitySpecialValue("gunpowder_tower_shrapnade", "damage");
  self.splashAOE = GetAbilitySpecialValue("gunpowder_tower_shrapnade", "splash_aoe");
  self.projOrigin = self.tower:GetAttachmentOrigin(self.tower:ScriptLookupAttachment("attach_attack1"));
end


RegisterTowerClass(GunpowderTower, GunpowderTower.className);