var glows = []
var hovering

function Hover(name, arg1, arg2, arg3) {
    $.Msg(name, arg1, arg2)

    AddElementGlow(arg1)
    if (arg2) AddElementGlow(arg2)
    if (arg3)
    {
        AddElementGlow(arg3)
        AddDualsGlow(arg1)
        AddDualsGlow(arg2)
        AddDualsGlow(arg3)
    }

    hovering = $("#"+name)
    hovering.AddClass("Glow_white")
    $.DispatchEvent( "DOTAShowAbilityTooltip", hovering, "item_upgrade_to_"+name+"_tower" );
}

function AddElementGlow(elem) {
    var panel = $("#"+elem)
    panel.AddClass("Glow_"+elem)
    panel.glow = "Glow_"+elem
    glows.push(panel)
}

function AddDualsGlow(elem) {
    var panel = $("#"+elem+"Duals")
    var childN = panel.GetChildCount()
    for (var i = 0; i < childN; i++) {
        var dual = panel.GetChild(i).GetChild(0)
        dual.AddClass("Glow_"+elem)
        dual.glow = "Glow_"+elem
        glows.push(dual)
    };
}

function OnMouseOut() {
    for (var i in glows)
    {
        glows[i].RemoveClass(glows[i].glow);
    }
    glows = []

    hovering.RemoveClass("Glow_white")
    $.DispatchEvent( "DOTAHideAbilityTooltip", hovering );
}

(function(){
    $.Msg("Tower Tree Loaded")
})()