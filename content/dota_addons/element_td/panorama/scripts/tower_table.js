var Root = $.GetContextPanel()
var Container = $("#Container")
var Filter = $("#FilterButtonContainer")
var glows = []
var hovering
var hidden = true
var towers = {}
towers['vapor'] = ['water','fire']
towers['well']  = ['water','nature']
towers['poison'] = ['dark','water']
towers['windstorm'] = ['water','fire','light']
towers['flooding'] = ['water','dark','nature']
towers['polar'] = ['water','light','earth']
towers['tidal'] = ['water','nature','light']
towers['blacksmith'] = ['fire','earth']
towers['electricity'] = ['fire','light']
towers['flame'] = ['fire','nature']
towers['haste'] = ['fire','earth','water']
towers['flamethrower'] = ['fire','dark','earth']
towers['erosion'] = ['fire','dark','water']
towers['life'] = ['nature','light']
towers['moss'] = ['nature','earth']
towers['impulse'] = ['nature','fire','water']
towers['roots'] = ['nature','dark','earth']
towers['ephemeral'] = ['nature','earth','water']
towers['enchantment'] = ['nature','light','earth']
towers['gunpowder'] = ['earth','dark']
towers['hydro'] = ['earth','water']
towers['gold'] = ['earth','fire','light']
towers['quake'] = ['earth','fire','nature']
towers['muck'] = ['earth','dark','water']
towers['ice'] = ['light','water']
towers['trickery'] = ['light','dark']
towers['quark'] = ['light','earth']
towers['hail'] = ['light','dark','water']
towers['nova'] = ['light','fire','nature']
towers['laser'] = ['light','dark','earth']
towers['disease'] = ['dark','nature']
towers['magic'] = ['dark','fire']
towers['jinx'] = ['dark','fire','nature']
towers['runic'] = ['dark','fire','light']
towers['obliteration'] = ['dark','light','nature']

Categories = {}
Categories['Buff_Towers'] = ["well","blacksmith","trickery","life","gold"]
Categories['Slow_Towers'] = ["windstorm", "roots", "nova","muck"]
Categories['Amp_Towers'] = ["erosion", "enchantment", "polar", "flamethrower"]
Categories['AoE_Towers'] = ["ice", "hail", "runic", "obliteration", "vapor", "poison", "flooding", "tidal", "electricity", "moss", "gunpowder", "hydro", "quake"]

function Hover(name, arg1, arg2, arg3) {
    AddElementGlow(arg1)
    if (arg2) AddElementGlow(arg2)
    if (arg3)
    {
        AddElementGlow(arg3)
        AddDualsGlow(arg1, arg2, arg3)
    }

    hovering = $("#"+name)
    hovering.AddClass("Glow_white")
    var tooltip_name = "item_upgrade_to_"+name+"_tower"
    if (hovering.BHasClass("DisabledAbility"))
        tooltip_name = tooltip_name+"_disabled"

    $.DispatchEvent( "DOTAShowAbilityTooltip", hovering, tooltip_name);
}

function HoverElement(name){
    AddElementGlow(name)
    hovering = $("#"+name)
    var tooltip_name = "build_"+name+"_tower"

    if (hovering.BHasClass("DisabledElement"))
        tooltip_name = tooltip_name+"_disabled"

    $.DispatchEvent( "DOTAShowAbilityTooltip", hovering, tooltip_name);
}

function OnMouseOutElement() {
    for (var i in glows)
    {
        glows[i].RemoveClass(glows[i].glow);
    }
    glows = []

    $.DispatchEvent( "DOTAHideAbilityTooltip", hovering );
}

function AddElementGlow(elem) {
    var panel = $("#"+elem)
    panel.AddClass("Glow_"+elem)
    panel.glow = "Glow_"+elem
    glows.push(panel)
}

function AddDualsGlow(elem1, elem2, elem3) {
    // Find each of the 3 possible dual combinations
    ResolveDualGlows(elem1, elem2, elem3)
    ResolveDualGlows(elem2, elem1, elem3)
    ResolveDualGlows(elem3, elem1, elem2)
}

function ResolveDualGlows(primary, secondary1, secondary2) {
    var panel = $("#"+primary+"Duals")
    var childN = panel.GetChildCount()
    for (var i = 0; i < childN; i++) {
        var dual = panel.GetChild(i).GetChild(0)
        if (towers[dual.id] !== undefined && (towers[dual.id].indexOf(secondary1) != -1 || towers[dual.id].indexOf(secondary2) != -1))
        {
            dual.AddClass("Glow_"+primary)
            dual.glow = "Glow_"+primary
            glows.push(dual)
        }
    };
}

function Toggle() {
    Game.EmitSound("ui_generic_button_click");
    hidden = !hidden
    Container.SetHasClass("Hidden", hidden)
    Filter.SetHasClass("Hidden", hidden)
}

function UpdateElements(data){
    for (var element in data)
    {
        var panel = $("#"+element)
        if (panel)
        {
            var level = data[element]
            panel.SetHasClass("DisabledElement", level==0)
        }
    }
    for (var towerName in towers)
    {
        CheckRequirements(towerName, towers[towerName], data)
    }
}

function CheckRequirements(towerName, requirements, data) {
    var panel = $("#"+towerName)
    if (panel)
    {
        var bRequirementFailed = false
        for (var i in requirements)
        {
            if (data[requirements[i]] == 0)
            {
                bRequirementFailed = true
                break
            }
        }
        panel.SetHasClass("DisabledAbility", bRequirementFailed)
    }
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

function HoverToggle()
{
    $.DispatchEvent("DOTAShowTitleTextTooltip", $("#ImageLabel"), "#etd_tower_table", "#etd_tower_table_description");
}

function OnMouseOutToggle()
{
    $.DispatchEvent( "DOTAHideAbilityTooltip", $("#ImageLabel"));
}

function HoverFilter(name) {
    var cat = Categories[name]
    for (var i in cat)
    {
        var tower = Root.FindChildTraverse(cat[i])
        if (tower)
        {
            var primary = towers[cat[i]][0]
            tower.AddClass("Glow_"+primary)
            tower.glow = "Glow_"+primary
            glows.push(tower)
        }
    }
}

function OnMouseOutFilter() {
    for (var i in glows)
    {
        glows[i].RemoveClass(glows[i].glow);
    }
    glows = []
}

(function(){
    $.Msg("Tower Tree Loaded")
    Container.AddClass("Hidden")
    GameEvents.Subscribe("glyph_override", Toggle )
    GameEvents.Subscribe("etd_update_elements", UpdateElements )

    Game.AddCommand( "+ToggleTowerTable", Toggle, "", 0 );
})()