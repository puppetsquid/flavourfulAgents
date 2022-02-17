local serverdefs = include( "modules/serverdefs" )

local TEMPLATE_AGENCY = 
{
	unitDefsPotential = {
		banks = serverdefs.createAgent( "stealth_2", {"augment_banks"} ),
	},
}

return
{
	TEMPLATE_AGENCY = TEMPLATE_AGENCY,	
	ORIGINAL_AGENCY = serverdefs.TEMPLATE_AGENCY,
}