local serverdefs = include( "modules/serverdefs" )

local TEMPLATE_AGENCY = 
{
	unitDefsPotential = {
		nat = serverdefs.createAgent( "engineer_2", {"augment_international_v1"} ),
	},
}

return
{
	TEMPLATE_AGENCY = TEMPLATE_AGENCY,	
	ORIGINAL_AGENCY = serverdefs.TEMPLATE_AGENCY,
}