"use strict";

var marksPath = "file://{resources}/layout/custom_game/minimap/marks/";
var bounds = null;

// Calculate relative image position
function GetRelativePosition( pos )
{
	var width = bounds["max"].x - bounds["min"].x;
	var height = bounds["max"].y - bounds["min"].y;

	var posX = pos[0] - bounds["min"].x;
	var posY = bounds["max"].y - pos[1];

	return [ posX / width, posY / height ];
}

// Calculate normal panel sizes
function GetPanelSize( panel )
{
	if (!panel)
		return { width: 0, height: 0 };

	return {
		width: panel.actuallayoutwidth * 1920 / Game.GetScreenWidth(),
		height: panel.actuallayoutheight * 1080 / Game.GetScreenHeight()
	}
}

function UpdateImagePosition( heroID )
{
	var relPos = GetRelativePosition( Entities.GetAbsOrigin(heroID) );

	var size = GetPanelSize( $( "#MinimapImage" ) );
	var parentSize = GetPanelSize( $( "#ImagePanel" ) );

	var offset = {
		x: -size.width * relPos[0] + parentSize.width / 2,
		y: -size.height * relPos[1] + parentSize.height / 2
	}

	if (!isNaN(offset.x) && !isNaN(offset.y))
	{
		$( "#MinimapImage" ).style.marginLeft = offset.x + "px;"
		$( "#MinimapImage" ).style.marginTop =  offset.y + "px;"
	}
}

function GetEntityAngle( entityID )
{
	var forward = Entities.GetForward( entityID );
	var offset = (forward[0] < 0 ? 270 : 90) 

	return offset - Math.atan(forward[1] / forward[0]) * 180 / 3.14;
}

function UpdatePointerPosition( heroID )
{
	var size = GetPanelSize( $( "#PointerImage" ) );
	var parentSize = GetPanelSize( $( "#ImagePanel" ) );

	var offset = {
		x: parentSize.width / 2 - size.width / 2,
		y: parentSize.height / 2 - size.height / 2
	}

	if (!isNaN(offset.x) && !isNaN(offset.y))
	{
		$( "#PointerImage" ).style.marginLeft = offset.x + "px;"
		$( "#PointerImage" ).style.marginTop =  offset.y + "px;"

		$( "#PointerImage" ).style.transform = "rotateZ(" + GetEntityAngle(heroID) + "deg);";		
	}
}

function RemoveUnusedMarks( units )
{
	var marksContainer = $( "#MarksMap" );
	var count = marksContainer.GetChildCount();

	for (var i = 0; i < count; i++) {
		var childID = marksContainer.GetChild(i).id;
		var entityID = childID.match(/[\d]+$/)[0];

		if (units.indexOf(Number(entityID)) == -1)
			marksContainer.GetChild(i).DeleteAsync(0.1);
	}
}

function SetEntityMapPostition( panel, entity )
{
	var size = GetPanelSize( panel );
	var parentSize = GetPanelSize( $( "#MinimapImage" ) );
	var relPos = GetRelativePosition( Entities.GetAbsOrigin(entity) );

	var offset = {
		x: parentSize.width * relPos[0] - size.width / 2,
		y: parentSize.height / 2 - size.height / 2
	}

	if (!isNaN(offset.x) && !isNaN(offset.y))
	{
		panel.style.marginLeft = parentSize.width * relPos[0] - size.width / 2 + "px;"
		panel.style.marginTop =  parentSize.height * relPos[1] - size.height / 2 + "px;"
	}	
}

// Get mark filename
function GetMarkType( entity )
{
	var type = "default";

	return type;
}

function CreateMarkPanel( entity )
{
	var panel = $.CreatePanel( "Panel", $( "#MarksMap" ), "Entity_" + entity );
	panel.BLoadLayout( marksPath + GetMarkType( entity ) +".xml", false, false );

	panel.entity = entity;

	if (panel.UpdateClass)
		panel.UpdateClass();
 
	return panel;
} 

// Filter units for minimap
function FilterUnits( heroID )
{
	var visionRange = Entities.GetCurrentVisionRange( heroID );	
	return Entities.GetAllEntities().filter(function( entity ) {
		return Entities.IsEntityInRange( heroID, entity, visionRange ) &&
			!Entities.IsInvisible( entity ) && 
			Entities.IsValidEntity( entity ) &&
			Entities.IsHero( entity ) &&
			heroID != entity;
	})
}

function UpdateUnits( heroID )
{
	var rangeUnits = FilterUnits( heroID );

	RemoveUnusedMarks( rangeUnits )

	for(var ent of rangeUnits)
	{
		var entPanel = $( "#MarksMap" ).FindChild("Entity_" + ent);
		if (!entPanel)
			entPanel = CreateMarkPanel( ent );

		SetEntityMapPostition( entPanel, ent );	
	}
}

function UpdateMinimap()
{
	var playerID = Players.GetLocalPlayer();
	var heroID = Players.GetPlayerHeroEntityIndex( playerID );

	UpdateImagePosition( heroID );
	UpdatePointerPosition( heroID );
	UpdateUnits( heroID );

	$.Schedule(0.05, UpdateMinimap); 
}

function MinimapClick()
{
	var mousePos = GameUI.GetCursorPosition();
	var containerPos = $( "#ImagePanel" ).GetPositionWithinWindow();

	var image = $( "#MinimapImage" );
	var offset = {
		x: ((mousePos[0] - containerPos.x) - image.actualxoffset) / image.actuallayoutwidth,
		y: ((mousePos[1] - containerPos.y) - image.actualyoffset) / image.actuallayoutheight
	}

	var x = bounds["min"].x + (bounds["max"].x - bounds["min"].x) * offset.x;
	var y = bounds["max"].y - (bounds["max"].y - bounds["min"].y) * offset.y;

	var order = {
		OrderType : dotaunitorder_t.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position : [x, y, 0],
		Queue : false,
		ShowEffects : false
	};

	Game.PrepareUnitOrders( order );
}

function SetWorldBounds( args ) 
{
	bounds = {};

	bounds["min"] = args.min;
	bounds["max"] = args.max;
	bounds["name"] = args.map;

	var image = $( "#MinimapImage" );
	image.SetImage( "file://{images}/custom_game/minimap/" + bounds["name"] + ".png" );
	$.Msg("file://{images}/custom_game/minimap/" + bounds["name"] + ".png");
 
	UpdateMinimap(); 
}

function ChangeMinimapMode()
{
	if ($.GetContextPanel().BHasClass("Hero"))
	{
		$.GetContextPanel().RemoveClass("Hero");
		$.GetContextPanel().AddClass("TopRight")
	}
	else
	{
		$.GetContextPanel().RemoveClass("TopRight");
		$.GetContextPanel().AddClass("Hero")
	}
}

(function()
{ 
	Game.AddCommand("+ZIVShowMinimap", ChangeMinimapMode, "", 0); 
	Game.AddCommand("-ZIVShowMinimap", ChangeMinimapMode, "", 0); 

	GameEvents.SendCustomGameEventToServer( "world_bounds_request", {} );
	GameEvents.Subscribe("world_bounds", SetWorldBounds);
})();