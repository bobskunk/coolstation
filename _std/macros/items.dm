
/// Returns true if the given x is an item.
#define isitem(x) istype(x, /obj/item)

#define istool(x,y) (isitem(x) && (x:tool_flags & (y)))
#define iscuttingtool(x) (istool(x, TOOL_CUTTING))
#define ispulsingtool(x) (istool(x, TOOL_PULSING))
#define ispryingtool(x) (istool(x, TOOL_PRYING))
#define isscrewingtool(x) (istool(x, TOOL_SCREWING) || (istype(x, /obj/item/reagent_containers) && x:reagents:has_reagent("screwdriver")) ) //the joke is too good
#define issnippingtool(x) (istool(x, TOOL_SNIPPING))
#define iswrenchingtool(x) (istool(x, TOOL_WRENCHING))
#define ischoppingtool(x) (istool(x, TOOL_CHOPPING))
#define isweldingtool(x) (istool(x, TOOL_WELDING))

#define isstool(x,y) (isitem(x) && (x:stool_flags & (y)))
#define isbucklestool(x) (isstool(x, STOOL_BUCKLES)) //has buckles (for safety)
#define iscuffstool(x) (isstool(x, STOOL_CUFFS)) //cuffs can be secured to it even if no buckles
#define isstepstool(x) (isstool(x, STOOL_STEP)) //you can stand on this to change a lightbulb or whatever
#define iswrestlingstool(x) (isstool(x, STOOL_WRESTLING)) //you can do a flip off this fucker
#define iswheelchair(x) (isstool(x, STOOL_WHEELCHAIR)) //you can do a roll in this fucker
#define isbed(x) (isstool(x, STOOL_BED)) //you can do a snooze in this fucker

/// Returns true if the given x is a grab (obj/item/grab)
#define isgrab(x) (istype(x, /obj/item/grab/))

/// Returns true if x is equipped or inside & usable in what's equipped (currently only applicable to magtractors)
#define equipped_or_holding(x,source) (source.equipped() == x || (source.equipped()?.useInnerItem && (x in source.equipped())))
