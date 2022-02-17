local serverdefs = include( "modules/serverdefs" )

local TEMPLATE_AGENCY = 
{
	unitDefsPotential = {
		decker = serverdefs.createAgent( "stealth_1", {"augment_deckard"} ),
	},
}

return
{
	TEMPLATE_AGENCY = TEMPLATE_AGENCY,	
	ORIGINAL_AGENCY = serverdefs.TEMPLATE_AGENCY,
}