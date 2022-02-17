local serverdefs = include( "modules/serverdefs" )

local TEMPLATE_AGENCY = 
{
	unitDefsPotential = {
		sharp = serverdefs.createAgent( "cyborg_1", {"augment_sharp_flav"} ),
	},
}

return
{
	TEMPLATE_AGENCY = TEMPLATE_AGENCY,	
	ORIGINAL_AGENCY = serverdefs.TEMPLATE_AGENCY,
}