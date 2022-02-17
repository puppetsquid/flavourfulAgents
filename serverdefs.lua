local serverdefs = include( "modules/serverdefs" )

local TEMPLATE_AGENCY = 
{
	unitDefsPotential = {
		prism = serverdefs.createAgent( "disguise_1", {"augment_prism_flav"} ),
	},
}

return
{
	TEMPLATE_AGENCY = TEMPLATE_AGENCY,	
	ORIGINAL_AGENCY = serverdefs.TEMPLATE_AGENCY,
}