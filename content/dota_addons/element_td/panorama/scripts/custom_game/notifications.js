if (!String.prototype.format) {
    String.prototype.format = function() {
        var str = this.toString();
        if (!arguments.length)
            return str;
        var args = typeof arguments[0],
            args = (("string" == args || "number" == args) ? arguments : arguments[0]);
        for (arg in args)
            str = str.replace(RegExp("\\{" + arg + "\\}", "gi"), args[arg]);
        return str;
    }
}

function TopNotification( msg ) {
  AddNotification(msg, $('#TopNotifications'));
}

function BottomNotification(msg) {
  AddNotification(msg, $('#BottomNotifications'));
}

function TopRemoveNotification(msg){
  RemoveNotification(msg, $('#TopNotifications'));
}

function BottomRemoveNotification(msg){
  RemoveNotification(msg, $('#BottomNotifications'));
}

function RemoveNotification(msg, panel){
  var count = msg.count;
  if (count > 0 && panel.GetChildCount() > 0){
    var start = panel.GetChildCount() - count;
    if (start < 0)
      start = 0;

    for (i=start;i<panel.GetChildCount(); i++){
      var lastPanel = panel.GetChild(i);
      //lastPanel.SetAttributeInt("deleted", 1);
      lastPanel.deleted = true;
      lastPanel.DeleteAsync(0);
    }
  }
}

function AddNotification(msg, panel) {
  var newNotification = true;
  var lastNotification = panel.GetChild(panel.GetChildCount() - 1)
  //$.Msg(msg)

  msg.continue = msg.continue || false;
  //msg.continue = true;

  if (lastNotification != null && msg.continue) 
    newNotification = false;

  if (newNotification){
    lastNotification = $.CreatePanel('Panel', panel, '');
    lastNotification.AddClass('NotificationLine')
    lastNotification.hittest = false;
  }

  var notification = null;
  
  if (msg.hero != null)
    notification = $.CreatePanel('DOTAHeroImage', lastNotification, '');
  else if (msg.image != null)
    notification = $.CreatePanel('Image', lastNotification, '');
  else if (msg.ability != null)
    notification = $.CreatePanel('DOTAAbilityImage', lastNotification, '');
  else if (msg.item != null)
    notification = $.CreatePanel('DOTAItemImage', lastNotification, '');
  else
    notification = $.CreatePanel('Label', lastNotification, '');

  if (typeof(msg.duration) != "number"){
    //$.Msg("[Notifications] Notification Duration is not a number!");
    msg.duration = 3
  }
  
  if (newNotification){
    $.Schedule(msg.duration, function(){
      //$.Msg('callback')
      if (lastNotification.deleted)
        return;
      
      lastNotification.DeleteAsync(0);
    });
  }

  if (msg.hero != null){
    notification.heroimagestyle = msg.imagestyle || "icon";
    notification.heroname = msg.hero
    notification.hittest = false;
  } else if (msg.image != null){
    notification.SetImage(msg.image);
    notification.hittest = false;
  } else if (msg.ability != null){
    notification.abilityname = msg.ability
    notification.hittest = false;
  } else if (msg.item != null){
    notification.itemname = msg.item
    notification.hittest = false;
  } else{
    notification.html = true;

    if (typeof msg.text == "object") {
      var text = msg.text.text || "No Text provided";
      notification.text = $.Localize(text).format(msg.text);
    }
    else {
      var text = msg.text || "No Text provided";
      notification.text = $.Localize(text)
    }

    notification.hittest = false;
    notification.AddClass('TitleText');
  }
  
  if (msg.class)
    notification.AddClass(msg.class);
  else
    notification.AddClass('NotificationMessage');

  if (msg.style){
    for (var key in msg.style){
      var value = msg.style[key]
      notification.style[key] = value;
    }
  }
}

var worldPanels = []

function WorldNotification(msg) {
  var entityIndex = msg.entityIndex;
  var text = msg.text || "No Text provided";

  // Don't let an entity have more than 1 active notification
  if (worldPanels[entityIndex])
  {
    var panel = $("#world_"+entityIndex)
    panel.deleted = true;
    panel.DeleteAsync(0)
  }

  var notification = $.CreatePanel('Label', $.GetContextPanel(), "world_"+entityIndex);
  notification.html = true;
  notification.text = $.Localize(text);
  notification.AddClass('WorldBox');
  
  worldPanels[entityIndex] = notification
  notification.entity = entityIndex
  notification.visible = false
  notification.hittest = false
}

function UpdateWorldPanelPositions() {
  for (var entityIndex in worldPanels)
  {
    var panel = worldPanels[entityIndex]
    if (! panel.deleted)
    {
      var worldPos = GetUnitScreenPosition(panel.entity)
      var offsetX = panel.actuallayoutwidth
      var offsetY = panel.actuallayoutheight
      var newX = worldPos.x-offsetX/2
      var newY = worldPos.y
      var maxX = $.GetContextPanel().actuallayoutwidth;
      var maxY = $.GetContextPanel().actuallayoutheight;
      if (newX+offsetX < 100 || newY+offsetY < 100 || newX > maxX+offsetX || newY > maxY+offsetY)
      {
        panel.visible = false
      }
      else
      {
        panel.visible = true
        var newPos = newX + "px " + newY + "px 0px";
        panel.style["position"] = newPos;
      }
    }
  }
  $.Schedule(1/60, UpdateWorldPanelPositions)
}

function GetUnitScreenPosition(entIndex){
  var origin = Entities.GetAbsOrigin(entIndex);
  return {x:Game.WorldToScreenX(origin[0], origin[1], origin[2]), y:Game.WorldToScreenY(origin[0], origin[1], origin[2])};
}

function WorldRemoveNotification(msg) {
  var entityIndex = msg.entityIndex
  var panel = $("#world_"+entityIndex)
  if (panel)
  {
    worldPanels.splice(entityIndex, 1)
    panel.deleted = true;
    panel.DeleteAsync(0)
  }
}

(function () {
  UpdateWorldPanelPositions()
  GameEvents.Subscribe( "top_notification", TopNotification );
  GameEvents.Subscribe( "bottom_notification", BottomNotification );
  GameEvents.Subscribe( "world_notification", WorldNotification)
  GameEvents.Subscribe( "top_remove_notification", TopRemoveNotification );
  GameEvents.Subscribe( "bottom_remove_notification", BottomRemoveNotification );
  GameEvents.Subscribe( "world_remove_notification", WorldRemoveNotification)
})();