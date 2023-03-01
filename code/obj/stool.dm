// CONTENTS:
// - Stools
// - Benches
// - Beds
// - Chairs
// - Syndicate Chairs (will trip you up)
// - Folded Chairs
// - Comfy Chairs
// - Shuttle Chairs
// - Wheelchairs
// - Wooden Chairs
// - Pews
// - Office Chairs
// - Electric Chairs

/* ================================================ */
/* -------------------- Stools -------------------- */
/* Basic parent class that's still useable. 4 legs. */
/* Climb? No, too small. No flipping off, either.	*/
/* Buckle? No.										*/
/* Cuffable? Nah. get a real chair, pig				*/
/* Custom acts? Not really.							*/
/* ================================================ */

/obj/stool
	name = "stool"
	desc = "A four-legged padded stool for crewmembers to relax on."
	icon = 'icons/obj/furniture/chairs.dmi'
	icon_state = "stool"
	flags = FPRINT | FLUID_SUBMERGE
	stool_flags = null
	throwforce = 10
	pressure_resistance = 3*ONE_ATMOSPHERE
	var/mob/living/occupant = null //may be standing on or buckled in
	//securing a user
	var/stool_flags = null // STOOL_BUCKLES, STOOL_CUFFS (isxstool(src))
	var/buckled = 0 //to know if the occupant's buckled or not (if cuffed in, 2)
	//standing on
	var/climbable = 0 //0 for cannot, 1 for all purpose, 2 for peaceful only, 3 for wrestle only
	var/ceilingreach = 0 //can this reach the ceiling if you stand on it
	var/flippable = 0 //needs sturdy surface to do it
	//stability
	var/loose = 0 //pranking, use screwdriver on certain non-caster'd chairs and stools, make them fall apart when sat on
	var/lying = 0 //did this get tipped over?
	//movement
	var/casters = 0 //does this have wheels? 1 for yes, 2 for yes and locked (easier to pull around, different scrape sound, done with screwdriver or, if chair is empty, open hand from stool.loc)
	var/securable = 0 //can it be fixed in place?
	var/rotatable = 0 //can you rotate it
	var/foldable = 0 //can you fold it?
	var/fold_type = null //if this folds, what object is created
	var/deconstructable = 1 //can you take it apart?
	var/parts_type = /obj/item/furniture_parts/stool
	var/list/roll_sounds = list( 'sound/misc/chair/office/scoot1.ogg', 'sound/misc/chair/office/scoot2.ogg', 'sound/misc/chair/office/scoot3.ogg', 'sound/misc/chair/office/scoot4.ogg', 'sound/misc/chair/office/scoot5.ogg' )
	var/list/drag_sounds = list("sound/misc/chair/normal/scoot1.ogg", "sound/misc/chair/normal/scoot2.ogg", "sound/misc/chair/normal/scoot3.ogg", "sound/misc/chair/normal/scoot4.ogg", "sound/misc/chair/normal/scoot5.ogg") //scrape
	var/obj/item/clothing/head/butt/has_butt = null // time for mature humour (thanks BatElite now i put it everywhere)
	var/allow_unbuckle = 1 //this is specifically for another Thing, just ignore it

	New()
		if (!src.anchored && src.casters) // wheels can be braked and we started unsecured
			src.p_class = 2 // so make us easy to move
		if (!src.anchored && !src.casters) // but if we don't have wheels and we aren't secure
			src.p_class = 3 // fuck off then
		..()

	ex_act(severity)
		switch(severity)
			if (1)
				qdel(src)
				return
			if (2)
				if (prob(50))
					if (src.deconstructable)
						src.deconstruct()
					else
						qdel(src)
					return
			if (3)
				if (prob(5))
					if (src.deconstructable)
						src.deconstruct()
					else
						qdel(src)
					return
			else
		return

	blob_act(var/power)
		if (prob(power * 2.5))
			var/obj/item/I = new /obj/item/raw_material/scrap_metal()
			I.set_loc(get_turf(src))

			if (src.material)
				I.setMaterial(src.material)
			else
				var/datum/material/M = getMaterial("steel")
				I.setMaterial(M)
			qdel(src)

	attackby(obj/item/W as obj, mob/user as mob)
		//loosen it
		if (iswrenchingtool(W) && src.deconstructable)
			actions.start(new /datum/action/bar/icon/furniture_deconstruct(src, W, 30), user)
			src.toggle_loose(user)
		//take it apart
		else if (isscrewingtool(W) && src.deconstructable && src.loose)
			playsound(src, "sound/items/Screwdriver.ogg", 100, 1)
			src.deconstruct(user)
			return
		//secure it so it doesn't move
		else if (isscrewingtool(W) && src.securable)
			src.toggle_secure(user)
			return
		else
			return ..()

	attack_hand(mob/user as mob)
		if (user.a_intent == "help" && src.lying)
			src.unfall_over()
			return
		if (user.a_intent == "disarm" && !src.anchored && !src.standing_on)
			src.fall_over()
			return
		if (user.a_intent == "grab" && src.climbable)
			src.stand_on()
			return
		if (src.can_sit(user))
			buckle_in(user, 3)
			return
		if (user == src.occupant && src.casters && src.securable)
			src.toggle_secure(user)
			return
		if (src.occupant && (src.occupant.standing_on == user))
			user.visible_message("<span class='notice'><b>[M]</b> steps off [H.standing_on].</span>", "<span class='notice'>You step off [src].</span>")
			unstand()
			return
		if (src.foldable) //only the living can fold
			if(src.occupant)
				var/mob/chump = src.occupant //chump detected
				for (var/mob/M in src.loc)
					if (!chump.sitting_on || !chump.standing_on) //no chump???
						chump = null
					if (user.standing_on == src) //graceful dismount
						user.visible_message("<span class='notice'><b>[M]</b> steps off [H.standing_on].</span>", "<span class='notice'>You step off [src].</span>")
						unstand()
						return
					if ((chump) && (chump != user)) //forced dismount
						chump.visible_message("<span class='alert'><b>[chump.name] falls off of [src]!</b></span>")
						unstand()
						//tear down the chump
						chump.changeStatus("weakened", 1 SECOND)
						chump.changeStatus("stunned", 2 SECONDS)
						random_brute_damage(chump, 15)
						playsound(chump.loc, "swing_hit", 50, 1)
			src.fold(user)
			return
		//if disarm intent push it over
			//(lying)
			//return

	MouseDrop_T(mob/M as mob, mob/user as mob)
		..()
		if (M == user)
			if (user.a_intent == INTENT_GRAB)
				stand_on(user) //hostile (flying piledriver or whatever)
		else
			return
	//
	toggle_secure(mob/user as mob)
		if (istype(get_turf(src), /turf/space)) //it's in space
			if (!src.casters)
				if (user)
					user.show_text("What exactly are you gunna secure [src] to?", "red")
					return
		if (user)
			if (src.casters)
				user.visible_message("<b>[user]</b> [src.anchored ? "loosens" : "tightens"] the casters of [src].[istype(src.loc, /turf/space) ? " It doesn't do much, though, since [src] is in space and all." : null]")
			else
				user.visible_message("<b>[user]</b> [src.anchored ? "unscrews [src] from" : "secures [src] to"] the floor.")
		playsound(src, "sound/items/Screwdriver.ogg", 100, 1)
		src.anchored = !(src.anchored)
		src.p_class = src.anchored ? initial(src.p_class) : 2
		return

	//checks. returns 0 if can't, 1 if can
/*	//buckle basics
	proc/can_buckle(var/mob/M, var/mob/user)
		if (!ticker)
			boutput(user, "You can't buckle anyone in before the game starts.")
			return 0
		if (M.buckled)
			boutput(user, "They're already buckled into something!", "red")
			return 0
		if (!( iscarbon(M) ) || get_dist(src, user) > 1 || M.loc != src.loc || user.restrained() || !isalive(user))
			return 0
		if(src.occupant && src.occupant.buckled == src && src.occupant != M)
			user.show_text("There's already someone buckled in [src]!", "red")
			return 0
		return 1
*/
	proc/can_buckle(var/mob/M, var/mob/user, var/buckle_type)
		//bitflags: 1: can buckle, 2: can cuff, 3: can sit
		var/buckleflags = 0

		//standard no-way-no-how checks for everything
		if (!M || (M.loc != src.loc))
			return 0 //target mob not in the area

		if (get_dist(src, user) > 1)
			user.show_text("[src] is too far away!", "red")
			return 0

		if (!iscarbon(M))
			return 0 //target can't use these things

		if ((!(iscarbon(user)) || user.restrained() || is_incapacitated(user) || !isalive(user)))
			return 0 //user can't do anything

		if (!ticker)
			boutput(user, "You can't buckle anyone in before the game starts.", "red")
			return 0

		if (M.buckled)
			boutput(user, "[hes_or_shes(C)] already buckled into something!", "red")
			return 0

		if (M.standing_on)
			boutput(user, "[hes_or_shes(C)] already standing on something!", "red")
			return 0

		switch(buckle_type)
			if(1) //buckle checks
			if(2) //cuff checks
			if(3) //sit checks

		if (C.buckled)
			boutput(user, "[hes_or_shes(C)] already buckled into something!", "red")
			return 0

		if(src.occupant && src.occupant.buckled == src && src.occupant != C)
			user.show_text("There's already someone buckled in [src]!", "red")
			return 0

		if(isbucklestool(src))
			bucklebits |= 1

		return  //no reason not to

		.= 0


	//doesn't care about possibilities, just gives you the most likely arrangement for your bucklee
	proc/buckle_type(mob/living/to_buckle)
		var/type = 0
		if(to_buckle.handcuffs) //cuffed takes priority
			if(iscuffstool(src))
				type = 1
			else if (isbucklestool(src)) //nowhere to secure cuffs? try buckles
				type = 2
			else
				type = 3 //oh well uh just sit down and don't go anywhere please
		else(isbucklestool(src)) //no cuffs? try buckles
			type = 2
		else //just a regular sit
			type = 3
		return type

	proc/buckle_in(mob/living/to_buckle, mob/living/user) //Handles the actual buckling in (and cuff-secure, and sitting, and bed)
		if(src.loose) //pranked
			user.visible_message("<span class='notice'[src] immediately falls apart when [to_buckle] sits on it!</span>", "<span class='notice'>[src] immediately falls apart when you sit on it!</span>")
			//force liedown, disorient, etc.
			to_buckle.changeStatus("weakened", 1 SECOND)
			to_buckle.changeStatus("stunned", 2 SECONDS)
			random_brute_damage(to_buckle, 10)
			//bar stool falls over
			//otherwise, instant disassemble into parts
			playsound(to_buckle.loc, "swing_hit", 50, 1)
			//var/obj/item/furniture_parts/P = new src.parts_type(src.loc)
			//SPAWN_DBG(0.1 SECONDS)
				//qdel(src)
			return

		//1 = seat buckle/straps, 2 = handcuff secure, 3 = just sitting down having a nice time :))))
		buckle_type(to_buckle)

		switch (type)
			if(1)
				if (!can_buckle(to_buckle,user))
					return
				if (to_buckle == user)
					user.visible_message("<span class='notice'><b>[to_buckle]</b> buckles in!</span>", "<span class='notice'>You buckle yourself in.</span>")
				else
					user.visible_message("<span class='notice'><b>[to_buckle]</b> is buckled in by [user].</span>", "<span class='notice'>You buckle in [to_buckle].</span>")
				to_buckle.setStatus("buckled", duration = INFINITE_STATUS)
				RegisterSignal(to_buckle, COMSIG_MOVABLE_SET_LOC, .proc/maybe_unbuckle)
			if(2)
				if (!can_buckle(to_buckle,user))
					return
				if (to_buckle == user)
					user.visible_message("<span class='notice'><b>[to_buckle]</b> secures [his_or_her(to_buckle)] handcuffs to \the [src] somehow!</span>", "<span class='notice'>You secure your handcuffs to \the [src]. Somehow.</span>")
				else
					user.visible_message("<span class='notice'><b>[user]</b> secures [to_buckle]'s handcuffs to \the [src].</span>", "<span class='notice'>You secure [to_buckle]'s handcuffs to \the [src].</span>")
				to_buckle.setStatus("buckled", duration = INFINITE_STATUS)
				RegisterSignal(to_buckle, COMSIG_MOVABLE_SET_LOC, .proc/maybe_unbuckle)
			if(3)
				if (!can_sit(to_buckle,user))
					return
				if (to_buckle == user)
					boutput(user, "<span class='notice'>You sit down on \the [src].</span>")
				else
					user.visible_message("<b>[user]</b> sits [to_buckle] down on \the [src].", "<span class='notice'>You sit [to_buckle]'s handcuffs to \the [src].</span>")
				to_buckle.setStatus("buckled", duration = INFINITE_STATUS)
				RegisterSignal(to_buckle, COMSIG_MOVABLE_SET_LOC, .proc/maybe_unsit)
			src.occupant = to_buckle
		return

	//Ditto but for unbuckling (may be obsolete if standing is split out)
	proc/unbuckle()
		if(isbed(src))
			occupant.force_laydown_standup()
		. = 0

	proc/maybe_unbuckle(source, turf/oldloc)
		// unbuckle if the guy is not on a turf, or if their chair is out of range and it's not a shuttle situation
		if(!isturf(occupant.loc) || (!IN_RANGE(src, oldloc, 1) && (!istype(get_area(src), /area/shuttle || !istype(get_area(oldloc), /area/shuttle)))))
			UnregisterSignal(occupant, COMSIG_MOVABLE_SET_LOC)
			unbuckle()

	proc/maybe_unsit(source, turf/oldloc)
		// if the spacer is not on a turf, or if out of range, get them out of stool, chair or bed
		if(!isturf(occupant.loc) || (!IN_RANGE(src, oldloc, 1) ))
			UnregisterSignal(occupant, COMSIG_MOVABLE_SET_LOC)
			unbuckle()

	proc/can_stand(var/mob/to_stand, var/mob/user)
		if(ishuman(to_stand))
			return 0 //humans only (for now)
		if (!isstepstool(src) && !iswrestlingstool(src))
			return 0 //can't climb on it
		if(src.occupant && user != src.occupant)
			return 0 //someone's already on this thing, and it isn't you
		if ((iswrestlingstool && !isstepstool) && !(iscarbon(to_stand)) || get_dist(src, to_stand) > 1))
			return 0 //target must meet criteria for being stood up (wrestling)
		else if ((!(iscarbon(to_stand)) || get_dist(src, to_stand) > 1 || to_stand.stat || !(isalive(to_stand)) || !(is_incapacitated(to_stand))))
			return 0 //target must meet criteria for being stood up (regular)
		if ((get_dist(src, user) > 1 || user.restrained() || user.stat || !(user.canmove) || !(isalive(to_stand || !(is_incapacitated(user)))))
			return 0 //user must meet criteria
		return 1 //send it

	//Handles the actual standing on
	proc/stand_on(mob/living/to_stand, mob/living/user, var/flip = 0) //let's stand up on this stool thing
		if(ON_COOLDOWN(to_stand, "chair_stand", 1 SECOND))
			return
		if (!can_stand(to_stand,user)) return

		if (flip) // fight stand
			if (H == user)
				user.visible_message("<span class='notice'><b>[to_stand]</b> climbs onto \the [src] with gusto and malice!</span>", "<span class='notice'>You climb up onto \the [src] and prepare to lay some hurt up ons.</span>")
			else
				user.visible_message("<span class='notice'><b>[to_stand]</b> is hefted up onto \the [src] by [user]!</span>", "<span class='notice'>You lift [to_stand] up onto \the [src]!</span>")
			to_stand.setStatus("standingonaggressive", duration = INFINITE_STATUS)

		else // lightbulb stand
			if (to_stand == user)
				H.visible_message("<span class='notice'><b>[to_stand]</b> climbs onto \the [src].</span>", "<span class='notice'>You climb up onto \the [src].</span>")
			else
				H.visible_message("<span class='notice'><b>[to_stand]</b> is helped up onto \the [src] by [user].</span>", "<span class='notice'>You help [to_stand] up onto \the [src].</span>")
			to_stand.setStatus("standingon", duration = INFINITE_STATUS)
			if (src.ceilingreach == 1)
				to_stand.ceilingreach = 1
				to_stand.lookingup = 1
				get_image_group(CLIENT_IMAGE_GROUP_CEILING_ICONS).add_mob(to_stand)
		RegisterSignal(to_stand, COMSIG_MOVABLE_SET_LOC, .proc/maybe_unstand)
		to_stand.set_loc(src.loc)
		to_stand.pixel_y = 10
		to_stand.standing_on = src
		src.occupant = to_stand
		if (src.anchored)
			to_buckle.anchored = 1
		return

	//Ditto but for getting your ass down
	//if chump = 1, you fell
	proc/unstand(violent=0)
		if(!src.occupant)
			return 0
		var/mob/M = src.occupant //get the nerd to do things to them
		if (M.standing_on == src)
			M.end_chair_flip_targeting() //regardless of peaceful
			M.pixel_y = 0 //reset height
			if (src.ceilingreach == 1) //clear out ceiling mode (improve this..)
				M.ceilingreach = 0
				M.lookingup = 0
				get_image_group(CLIENT_IMAGE_GROUP_CEILING_ICONS).remove_mob(M)
			UnregisterSignal(src.occupant, COMSIG_MOVABLE_SET_LOC) //no longer dump them on their ass if it moves
			reset_anchored(src.occupant)

			SPAWN_DBG(0.5 SECONDS)
				M.standing_on = null
				src.occupant = null
			return 1
		else
			return 0

		proc/maybe_unstand(source, turf/oldloc)
		// unstand if the spacer is not on a turf, or if their standing-item is out of range (especially if it's a shuttle situation)
		// make them fall on their asssssssss
		if(!isturf(occupant.loc) || (!IN_RANGE(src, oldloc, 1) ))
			UnregisterSignal(occupant, COMSIG_MOVABLE_SET_LOC)
			unstand()

	proc/toggle_loose(mob/user as mob)
		//cases: two steps to taking a chair apart, unlike tables they generally aren't in the way. good for pranks.
		//meant to take wrench, then screwdriver for final disassembly
		if (!src.deconstructable)
			user.visible_message("It doesn't look like you can take \the [src] apart at all.")
			return
		if (user)
			user.visible_message("<b>[user]</b> [src.loose ? "loosens" : "tightens"] the [src]'s parts.[src.loose ? " It looks pretty unstable." : "It looks safe enough to sit on."]")
		playsound(src.loc, "sound/items/Ratchet.ogg", 50, 1)
		src.loose = !(src.loose)
		return

	proc/deconstruct() //take it all the way apart
		if (!src.deconstructable)
			user.visible_message("It doesn't look like you can take \the [src] apart at all.")
			return
		if (!src.loose) //another quick check here
			user.visible_message("\The [src] needs to be loosened up with a wrench first.")
			return
		if (ispath(src.parts_type)) //if there are parts, give parts
			var/obj/item/furniture_parts/P = new src.parts_type(src.loc)
			if (P && src.material)
				P.setMaterial(src.material)
		else //otherwise, default to a sheet of metal
			playsound(src, "sound/items/Screwdriver.ogg", 50, 1)
			var/obj/item/sheet/S = new (src.loc)
			if (src.material)
				S.setMaterial(src.material)
			else
				var/datum/material/M = getMaterial("steel")
				S.setMaterial(M)
		//visible message for taking apart the item
		//double check that anyone who is buckled in any way is immediately and silently unbuckled
		qdel(src)
		return

	proc/fold(var/mob/user as mob) //fold it down
		if (!src.foldable) //should not see this
			user.visible_message("You can't fold \the [src] at all. This is a coder's fault, somehow.")
			return 0
		if (ispath(src.fold_type)) //get what it folds into
			var/obj/item/F = new src.fold_type(src.loc)
			F.add_fingerprint(user)
			if (F && src.material)
				F.setMaterial(src.material)
			if (src.icon_state && istype(F, /obj/item/chair/folded))
				F.variety = src.icon_state
				F.icon_state = "folded_[src.icon_state]"
				F.item_state = F.icon_state
			user.visible_message("<span class='notice'><b>[user]</b> folds \the [src].</span>", "<span class='notice'>You fold \the[src].</span>")
			qdel(src)
			return 1
		else //whoops
			user.visible_message("\The [src] may be foldable, but you have NO idea how to do it. Ask a coder?")
		return 0

	//the prank proc
	proc/fall_over(var/turf/T)
		if (src.lying) //already over?
			return 0
		if (src.anchored && !istype(src, /obj/stool/bar)) //this is fixed in place securely and can't fall (unless it's a loose barstool)
			return 0
		if (src.occupant) //someone on it?
			var/mob/living/M = src.occupant //let's see if they were really on it
			if(src.occupant.standing_on == src) //someone STANDING? uh oh
				src.unstand() //get them off and onto their ass
			if(src.loose)
				src.unbuckle() //this thing probably fell apart, so, let's double check
			if (M && !src.occupant) //yep, definitely using this thing
				if (iswheelchair(src)) //was it a wheelchair?
					src.unbuckle()
					M.visible_message("<span class='alert'>[M] is tossed out of [src] as it [src.loose ? "comes apart" : "tips [T ? "while rolling over [T]" : "over"]"]!</span>",\
					"<span class='alert'>You're tossed out of [src] as it [src.loose ? "comes apart" : "tips [T ? "while rolling over [T]" : "over"]"]!</span>")
					var/turf/target = get_edge_target_turf(src, src.dir)
					M.throw_at(target, 5, 1)
				else //oh it was something else
					if (!src.occupant.handcuffs && !src.buckled)
						src.unbuckle()
						M.visible_message("<span class='alert'>[M] falls down as [src] [src.loose ? "comes apart" : "falls over"]!</span>",\
						"<span class='alert'>You fall on your ass as [src] [src.loose ? "comes apart" : "falls over"]!</span>")
						M.changeStatus("stunned", 4 SECONDS)
						M.changeStatus("weakened", 4 SECONDS)
					else //oh you were REALLY on there when it went down, and you're still attached.
						M.visible_message("<span class='alert'>[M] goes down hard as [src] [src.loose ? "comes apart" : "falls over"]!</span>",\
						"<span class='alert'>You go down hard as the [src] [src.loose ? "comes apart" : "falls over"]!</span>")
						M.changeStatus("stunned", 8 SECONDS)
						M.changeStatus("weakened", 4 SECONDS)
			else //nobody actually using it
				src.visible_message("<span class='alert'>[src] tips [T ? "as it moves over [T]" : "over"]!</span>")
		else //nobody on it at all
			src.visible_message("<span class='alert'>[src] tips [T ? "as it moves over [T]" : "over"]!</span>")
		//flip the thing over
		src.lying = 1
		animate_rest(src, !src.lying)
		src.p_class = initial(src.p_class) + src.lying // 1 p_class worse when lying down/dragged around
		if src.loose
			src.deconstruct() //now it fell apart
		return 1

	proc/unfall_over()
		if(src.lying)
			user.visible_message("[user] sets [src] upright again.",\
			"You set [src] upright again.")
			src.lying = 0
			animate_rest(src, !src.lying)
			src.p_class = initial(src.p_class) + src.lying // 2 while standing, 3 while lying
			return 1
		else
			return

	Move(atom/target)
		. = ..()
		if (. && casters && !casterslocked && prob(75))
			playsound( get_turf(src), pick( roll_sounds ), 50, 1 )
		else if (prob(75)) //scrape it
			playsound( get_turf(src), pick( drag_sounds ), 50, 1 )

/obj/stool/bee_bed
	// idk. Not a bed proper since humans can't lay in it. Weirdos.
	// would also be cool to make these work with bees.
	// it's hip to tuck bees!
	name = "bee bed"
	icon = 'icons/misc/critter.dmi'
	icon_state = "beebed"
	desc = "A soft little bed the general size and shape of a space bee."
	parts_type = /obj/item/furniture_parts/stool/bee_bed
	climbable = 0
	buckles = 0

/obj/stool/bar
	name = "bar stool"
	icon_state = "bar-stool"
	desc = "Like a stool, but in a bar."
	parts_type = /obj/item/furniture_parts/stool/bar
	flippable = 1
	unstable = 1
	//if you sit on this and it's not secured (screwdriver)
	//tip it over and fall on your ass

/obj/stool/wooden
	name = "wooden stool"
	icon_state = "wstool"
	desc = "Like a stool, but just made out of wood."
	parts_type = /obj/item/furniture_parts/woodenstool

/* =================================================*/
/* -------------------- Benches --------------------*/
/* Connects in rows, looks pretty nice like that.   */
/* Climb? No, too small. No flipping off, either.	*/
/* Buckle? No, no buckles. It's a stool.			*/
/* Cuffable? Sure why not. Attach to a leg.			*/
/* Custom acts? No.woodenstool						*/
/* =================================================*/

/obj/stool/bench
	name = "bench"
	desc = "It's a bench! You can sit on it!"
	icon = 'icons/obj/furniture/bench.dmi'
	stool_flags = STOOL_CUFFS
	icon_state = "0"
	anchored = 1
	var/auto = 0
	var/auto_path = null
	parts_type = /obj/item/furniture_parts/bench

	New()
		..()
		SPAWN_DBG(0)
			if (src.auto && ispath(src.auto_path))
				src.set_up(1)

	proc/set_up(var/setup_others = 0)
		if (!src.auto || !ispath(src.auto_path))
			return
		var/dirs = 0
		for (var/dir in cardinal)
			var/turf/T = get_step(src, dir)
			if (locate(src.auto_path) in T)
				dirs |= dir
		icon_state = num2text(dirs)
		if (setup_others)
			for (var/obj/stool/bench/B in orange(1,src))
				if (istype(B, src.auto_path))
					B.set_up()

	//todo: add buckle/stand climb up proc without any of the buckling

	deconstruct()
		if (!src.deconstructable)
			return
		var/oldloc = src.loc
		..()
		for (var/obj/stool/bench/B in orange(1,oldloc))
			if (B.auto)
				B.set_up()
		return

/obj/stool/bench/auto
	auto = 1
	auto_path = /obj/stool/bench/auto

/* ---------- Red ---------- */

/obj/stool/bench/red
	icon = 'icons/obj/furniture/bench_red.dmi'
	parts_type = /obj/item/furniture_parts/bench/red

/obj/stool/bench/red/auto
	auto = 1
	auto_path = /obj/stool/bench/red/auto

/* ---------- Blue ---------- */

/obj/stool/bench/blue
	icon = 'icons/obj/furniture/bench_blue.dmi'
	parts_type = /obj/item/furniture_parts/bench/blue

/obj/stool/bench/blue/auto
	auto = 1
	auto_path = /obj/stool/bench/blue/auto

/* ---------- Green ---------- */

/obj/stool/bench/green
	icon = 'icons/obj/furniture/bench_green.dmi'
	parts_type = /obj/item/furniture_parts/bench/green

/obj/stool/bench/green/auto
	auto = 1
	auto_path = /obj/stool/bench/green/auto

/* ---------- Yellow ---------- */

/obj/stool/bench/yellow
	icon = 'icons/obj/furniture/bench_yellow.dmi'
	parts_type = /obj/item/furniture_parts/bench/yellow

/obj/stool/bench/yellow/auto
	auto = 1
	auto_path = /obj/stool/bench/yellow/auto

/* ---------- Wooden ---------- */

/obj/stool/bench/wooden
	icon = 'icons/obj/furniture/bench_wood.dmi'
	parts_type = /obj/item/furniture_parts/bench/wooden

/obj/stool/bench/wooden/auto
	auto = 1
	auto_path = /obj/stool/bench/wooden/auto

/* ---------- Sauna ---------- */

/obj/stool/bench/sauna
	icon = 'icons/obj/furniture/chairs.dmi'
	icon_state = "saunabench"

/* ============================================== */
/* -------------------- Beds -------------------- */
/* You sleep in these fuckin' things.   		  */
/* Climb? Hell yeah. Flip off it into people too. */
/* Buckle? Not unless it's a hospital bed.		  */
/* Cuffable? Sure why not. Attach to a leg.		  */
/* Custom acts? Tucking in, sleeping in, sheets.  */
/* ============================================== */

/obj/stool/bed
	name = "bed"
	desc = "A solid metal frame with some padding on it, useful for sleeping on."
	icon_state = "bed"
	anchored = 1
	stool_flags = STOOL_CUFFS
	var/security = 0
	var/obj/item/clothing/suit/bedsheet/Sheet = null
	parts_type = /obj/item/furniture_parts/bed

	brig
		name = "brig cell bed"
		desc = "It doesn't look very comfortable. Fortunately there's no way to be buckled to it."
		deconstructable = 0
		parts_type = null

	moveable
		name = "roller bed"
		desc = "A solid metal frame with some padding on it, useful for sleeping on. This one has little wheels on it, neat!"
		anchored = 0
		casters = 1
		securable = 1
		icon_state = "rollerbed"
		parts_type = /obj/item/furniture_parts/bed/roller
		scoot_sounds = list( 'sound/misc/chair/office/scoot1.ogg', 'sound/misc/chair/office/scoot2.ogg', 'sound/misc/chair/office/scoot3.ogg', 'sound/misc/chair/office/scoot4.ogg', 'sound/misc/chair/office/scoot5.ogg' )

		//hosp bed in another dm

	Move()
		if(src.occupant?.loc != src.loc)
			src.unbuckle()
		. = ..()
		if (. && src.occupant)
			var/mob/living/carbon/C = src.occupant
			C.buckled = null
			C.Move(src.loc)
			C.buckled = src

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/clothing/suit/bedsheet))
			src.tuck_sheet(W, user)
			return
		if (iswrenchingtool(W) && !src.deconstructable)
			boutput(user, "<span class='alert'>You briefly ponder how to go about disassembling a featureless slab using a wrench. You quickly give up.</span>")
			return
		else
			return ..()

	attack_hand(mob/user as mob)
		..()
		if (src.Sheet)
			src.untuck_sheet(user)
		for (var/mob/M in src.loc)
			src.unbuckle_mob(M, user)
		return

	can_buckle(var/mob/living/carbon/C, var/mob/user)

		if (!C || (C.loc != src.loc))
			return 0

		if ((!(iscarbon(C)) || C.loc != src.loc || user.restrained() || is_incapacitated(user) || !isalive(user)))
			return 0

		if (get_dist(src, user) > 1)
			user.show_text("[src] is too far away!", "red")
			return 0

		if (!ticker)
			boutput(user, "You can't buckle anyone in before the game starts.", "red")
			return 0

		if (!isbucklestool(src) && !iscuffstool(src))
			boutput(user, "There's nothing you can buckle them to!", "red")
			return 0

		if (C.buckled)
			boutput(user, "[hes_or_shes(C)] already buckled into something!", "red")
			return 0

		if(src.occupant && src.occupant.buckled == src && src.occupant != C)
			user.show_text("There's already someone buckled in [src]!", "red")
			return 0

		return 1 //no reason not to

	unbuckle()
		..()
		if(src.occupant && src.occupant.buckled == src)
			reset_anchored(occupant)
			occupant.buckled = null
			occupant.force_laydown_standup()
			src.occupant = null
			playsound(src, "sound/misc/belt_click.ogg", 50, 1)

	proc/tuck_sheet(var/obj/item/clothing/suit/bedsheet/newSheet as obj, var/mob/user as mob) //bed exclusive. this works.
		if (!newSheet || newSheet.cape || (src.Sheet == newSheet && newSheet.loc == src.loc)) // if we weren't provided a new bedsheet, the new bedsheet we got is tied into a cape, or the new bedsheet is actually the one we already have and is still in the same place as us...
			return // nevermind

		if (src.Sheet && src.Sheet.loc != src.loc) // a safety check: do we have a sheet and is it not where we are?
			if (src.Sheet.Bed && src.Sheet.Bed == src) // does our sheet have us listed as its bed?
				src.Sheet.Bed = null // set its bed to null
			src.Sheet = null // then set our sheet to null: it's not where we are!

		if (src.Sheet && src.Sheet != newSheet) // do we have a sheet, and is the new sheet we've been given not our sheet?
			user.show_text("You try to kinda cram [newSheet] into the edges of [src], but there's not enough room with [src.Sheet] tucked in already!", "red")
			return // they're crappy beds, okay?  there's not enough space!

		if (!src.Sheet && (newSheet.loc == src.loc || user.find_in_hand(newSheet))) // finally, do we have room for the new sheet, and is the sheet where we are or in the hand of the user?
			src.Sheet = newSheet // let's get this shit DONE!
			newSheet.Bed = src
			user.u_equip(newSheet)
			newSheet.set_loc(src.loc)
			mutual_attach(src, newSheet)

			var/mob/somebody
			if (src.occupant)
				somebody = src.occupant
			else
				somebody = locate(/mob/living/carbon) in get_turf(src)
			if (somebody?.lying)
				user.tri_message("<span class='notice'><b>[user]</b> tucks [somebody == user ? "[him_or_her(user)]self" : "[somebody]"] into bed.</span>",\
				user, "<span class='notice'>You tuck [somebody == user ? "yourself" : "[somebody]"] into bed.</span>",\
				somebody, "<span class='notice'>[somebody == user ? "You tuck yourself" : "<b>[user]</b> tucks you"] into bed.</span>")
				newSheet.layer = EFFECTS_LAYER_BASE-1
				return
			else
				user.visible_message("<span class='notice'><b>[user]</b> tucks [newSheet] into [src].</span>",\
				"<span class='notice'>You tuck [newSheet] into [src].</span>")
				return

	proc/untuck_sheet(var/mob/user as mob)
		if (!src.Sheet) // vOv
			return // there's nothing to do here, everyone go home

		var/obj/item/clothing/suit/bedsheet/oldSheet = src.Sheet

		if (user)
			var/mob/somebody
			if (src.occupant)
				somebody = src.occupant
			else
				somebody = locate(/mob/living/carbon) in get_turf(src)
			if (somebody?.lying)
				user.tri_message("<span class='notice'><b>[user]</b> untucks [somebody == user ? "[him_or_her(user)]self" : "[somebody]"] from bed.</span>",\
				user, "<span class='notice'>You untuck [somebody == user ? "yourself" : "[somebody]"] from bed.</span>",\
				somebody, "<span class='notice'>[somebody == user ? "You untuck yourself" : "<b>[user]</b> untucks you"] from bed.</span>")
				oldSheet.layer = initial(oldSheet.layer)
			else
				user.visible_message("<span class='notice'><b>[user]</b> untucks [oldSheet] from [src].</span>",\
				"<span class='notice'>You untuck [oldSheet] from [src].</span>")

		if (oldSheet.Bed == src) // just in case it's somehow not us
			oldSheet.Bed = null
		mutual_detach(src, oldSheet)
		src.Sheet = null
		return

	MouseDrop_T(atom/A as mob|obj, mob/user as mob)
		if (get_dist(src, user) > 1 || A.loc != src.loc || user.restrained() || !isalive(user))
			..()
		else if (istype(A, /obj/item/clothing/suit/bedsheet))
			if ((!src.Sheet || (src.Sheet && src.Sheet.loc != src.loc)) && A.loc == src.loc)
				src.tuck_sheet(A, user)
				return
			if (src.Sheet && A == src.Sheet)
				src.untuck_sheet(user)
				return

		else if (ismob(A))
			src.buckle_in(A, user)
			var/mob/M = A
			if (isdead(M) && M != user && emergency_shuttle?.location == SHUTTLE_LOC_STATION) // 1 should be SHUTTLE_LOC_STATION
				var/area/shuttle/escape/station/area = get_area(M)
				if (istype(area))
					user.unlock_medal("Leave no man behind!", 1)
			src.add_fingerprint(user)
		else
			return ..()

	disposing()
		for (var/mob/M in src.loc)
			if (M.buckled == src)
				M.buckled = null
				src.occupant = null
				M.lying = 0
				reset_anchored(M)
		if (src.Sheet && src.Sheet.Bed == src)
			src.Sheet.Bed = null
			src.Sheet = null
		..()
		return

	proc/sleep_in(var/mob/M)
		if (!ishuman(M))
			return

		var/mob/living/carbon/user = M

		if (isdead(user))
			boutput(user, "<span class='alert'>Some would say that death is already the big sleep.</span>")
			return

		if ((get_turf(user) != src.loc) || (!user.lying))
			boutput(user, "<span class='alert'>You must be lying down on [src] to sleep on it.</span>")
			return

		user.setStatus("resting", INFINITE_STATUS)
		user.sleeping = 4
		if (ishuman(user))
			var/mob/living/carbon/human/H = user
			H.hud.update_resting()
		return

/* ================================================ */
/* -------------------- Chairs -------------------- */
/* ================================================ */

/obj/stool/chair
	name = "chair"
	desc = "A four-legged metal chair, rigid and slightly uncomfortable. Helpful when you don't want to use your legs at the moment."
	icon_state = "chair"
	var/comfort_value = 3
	var/status = 0
	var/rotatable = 1
	var/stable = 0 //will you fuck up less if you climb on or jump from this?
	foldable = 1
	fold_type = /obj/item/chair/folded
	climbable = 1

	var/buckle_move_delay = 6 // this should have been a var somepotato WHY WASN'T IT A VAR
	var/obj/item/clothing/head/butt/has_butt = null // time for mature humour
	var/image/butt_img
	securable = 1
	anchored = 1
	deconstruct()
		. = ..()

	parts_type = null

	moveable
		anchored = 0

	New()
		if (src.dir == NORTH)
			src.layer = FLY_LAYER+1
		butt_img = image('icons/obj/furniture/chairs.dmi')
		butt_img.layer = OBJ_LAYER + 0.5 //In between OBJ_LAYER and MOB_LAYER
		..()
		return

	Move()
		. = ..()
		if (.)
			if (src.dir == NORTH)
				src.layer = FLY_LAYER+1
			else
				src.layer = OBJ_LAYER

			if (src.occupant)
				var/mob/living/carbon/C = src.occupant
				C.buckled = null
				C.Move(src.loc)
				C.buckled = src

	attackby(obj/item/W as obj, mob/user as mob)
		if (ispryingtool(W) && has_butt)
			user.put_in_hand_or_drop(has_butt)
			boutput(user, "<span class='notice'>You pry [has_butt.name] from [name].</span>")
			has_butt = null
			UpdateOverlays(null, "chairbutt")
			return
		if (istype(W, /obj/item/clothing/head/butt) && !has_butt)
			has_butt = W
			user.u_equip(has_butt)
			has_butt.set_loc(src)
			boutput(user, "<span class='notice'>You place [has_butt.name] on [name].</span>")
			butt_img.icon_state = "chair_[has_butt.icon_state]"
			UpdateOverlays(butt_img, "chairbutt")
			return
		if (istype(W, /obj/item/assembly/shock_kit))
			var/obj/stool/chair/e_chair/E = new /obj/stool/chair/e_chair(src.loc)
			if (src.material)
				E.setMaterial(src.material)
			playsound(src.loc, "sound/items/Deconstruct.ogg", 50, 1)
			E.set_dir(src.dir)
			E.part1 = W
			W.set_loc(E)
			W.master = E
			user.u_equip(W)
			W.layer = initial(W.layer)
			qdel(src)
			return
		else
			return ..()

	attack_hand(mob/user as mob)
		if (!ishuman(user)) return
		var/mob/living/carbon/human/H = user
		var/mob/living/carbon/human/chump = null
		for (var/mob/M in src.loc)

			if (ishuman(M))
				chump = M
			if (!chump || !chump.standing_on)// == 1)
				chump = null
			if (H.standing_on)// == 1)
				if (M == user)
					user.visible_message("<span class='notice'><b>[M]</b> steps off [H.standing_on].</span>", "<span class='notice'>You step off [src].</span>")
					src.add_fingerprint(user)
					unbuckle()
					return

			if ((M.buckled) && (!H.standing_on))
				if (allow_unbuckle)
					if(user.restrained())
						return
					if (M != user)
						user.visible_message("<span class='notice'><b>[M]</b> is unbuckled by [user].</span>", "<span class='notice'>You unbuckle [M].</span>")
					else
						user.visible_message("<span class='notice'><b>[M]</b> unbuckles.</span>", "<span class='notice'>You unbuckle.</span>")
					src.add_fingerprint(user)
					unbuckle()
					return
				else
					user.show_text("Seems like the buckle is firmly locked into place.", "red")
					return

		if (!src.buckled)
			if (src.foldable)
				src.fold(user)
				if ((chump) && (chump != user))
					chump.visible_message("<span class='alert'><b>[chump.name] falls off of [src]!</b></span>")
					chump.standing_on = 0
					chump.pixel_y = 0
					chump.ceilingreach = 0
					chump.changeStatus("weakened", 1 SECOND)
					chump.changeStatus("stunned", 2 SECONDS)
					random_brute_damage(chump, 15)
					playsound(chump.loc, "swing_hit", 50, 1)

				var/obj/item/chair/folded/C = new/obj/item/chair/folded(src.loc)
				if (src.material)
					C.setMaterial(src.material)
				if (src.icon_state)
					C.c_color = src.icon_state
					C.icon_state = "folded_[src.icon_state]"
					C.item_state = C.icon_state
				if (!src.fold_type)
					//you have NO idea how to fold this thing and you give up
					return
				else
					qdel(src)
			else
				src.rotate()
		return

	MouseDrop_T(mob/M as mob, mob/user as mob)
		..()
		if (M == user)
			if (user.a_intent == INTENT_GRAB)
				if(climbable)
					stand_on(M, user, 1)
				else
					boutput(user, "<span class='alert'>[src] isn't climbable.</span>")
			/*else if (user.a_intent == INTENT_DISARM)
				if(climbable)
					buckle_in(M, user, 2)
				else
					boutput(user, "<span class='alert'>[src] isn't climbable.</span>")*/
			else
				buckle_in(M,user)
		else
			buckle_in(M,user)
			if (isdead(M) && M != user && emergency_shuttle?.location == SHUTTLE_LOC_STATION) // 1 should be SHUTTLE_LOC_STATION
				var/area/shuttle/escape/station/A = get_area(M)
				if (istype(A))
					user.unlock_medal("Leave no man behind!", 1)
		return

	MouseDrop(atom/over_object as mob|obj)
		if(get_dist(src,usr) <= 1)
			src.rotate(get_dir(get_turf(src),get_turf(over_object)))
		..()

	can_buckle(var/mob/M, var/mob/user)
		if (!ticker)
			boutput(user, "You can't buckle anyone in before the game starts.")
			return 0
		if (M.buckled)
			boutput(user, "They're already buckled into something!", "red")
			return 0
		if (!( iscarbon(M) ) || get_dist(src, user) > 1 || M.loc != src.loc || user.restrained() || !isalive(user))
			return 0
		if(src.occupant && src.occupant.buckled == src && src.occupant != M)
			user.show_text("There's already someone buckled in [src]!", "red")
			return 0
		return 1

	buckle_in(mob/living/to_buckle, mob/living/user, var/stand = 0)
		if(!istype(to_buckle))
			return
		if(user.hasStatus("weakened"))
			return
		if(src.occupant && src.occupant.buckled == src && to_buckle != src.occupant) return

		if (!can_buckle(to_buckle,user))
			return

	fold(var/mob/user as mob) //fold it down and preserve materials/color
		if (!src.foldable)
			user.visible_message("You can't fold \the [src] at all. This is a coder's fault, somehow.")
			return 0
		if (ispath(src.fold_type)) //if there are parts, give parts
			var/obj/item/C = new src.fold_type(src.loc)
			if (src.material)
				C.setMaterial(src.material)
			if (src.icon_state)
				C.c_color = src.icon_state
				C.icon_state = "folded_[src.icon_state]"
				C.item_state = C.icon_state
			user.visible_message("<span class='notice'><b>[user]</b> folds \the [src].</span>", "<span class='notice'>You fold \the[src].</span>")
			qdel(src)
			return 1
		else //otherwise, default to a sheet of metal
			user.visible_message("\The [src] may be foldable, but you have NO idea how to do it. Ask a coder?")
		return 0

//movetostand
/*
			if(ON_COOLDOWN(to_buckle, "chair_stand", 1 SECOND))
				return
			user.visible_message("<span class='notice'><b>[to_buckle]</b> climbs up on [src] with a dangerous flair!</span>", "<span class='notice'>You climb up on [src].</span>")

			var/mob/living/carbon/human/H = to_buckle
			stand
			to_buckle.set_loc(src.loc)
			to_buckle.pixel_y = 10
			H.ceilingreach = 1
			if (src.anchored)
				to_buckle.anchored = 1
			H.standing_on = src
			to_buckle.buckled = src
			src.occupant = to_buckle
			src.buckled = 1
			to_buckle.setStatus("buckled", duration = INFINITE_STATUS)
			H.start_chair_flip_targeting()
		if(stand == 2)
			if(ON_COOLDOWN(to_buckle, "chair_stand", 1 SECOND))
				return
			user.visible_message("<span class='notice'><b>[to_buckle]</b> climbs up on [src].</span>", "<span class='notice'>You climb up on [src].</span>")

			var/mob/living/carbon/human/H = to_buckle
			to_buckle.set_loc(src.loc)
			to_buckle.pixel_y = 10
			H.ceilingreach = 1
			if (src.anchored)
				to_buckle.anchored = 1
			H.standing_on = src
			to_buckle.buckled = src
			src.occupant = to_buckle
			src.buckled = 1
			to_buckle.setStatus("buckled", duration = INFINITE_STATUS)
			H.start_chair_flip_targeting()
		else

			if (to_buckle == user)
				user.visible_message("<span class='notice'><b>[to_buckle]</b> buckles in!</span>", "<span class='notice'>You buckle yourself in.</span>")
			else
				user.visible_message("<span class='notice'><b>[to_buckle]</b> is buckled in by [user].</span>", "<span class='notice'>You buckle in [to_buckle].</span>")

			if (src.anchored)
				to_buckle.anchored = 1
			to_buckle.buckled = src
			src.occupant = to_buckle
			to_buckle.set_loc(src.loc)
			src.buckled = 1
			to_buckle.setStatus("buckled", duration = INFINITE_STATUS)
		if (has_butt)
			playsound(src, (has_butt.sound_fart ? has_butt.sound_fart : 'sound/voice/farts/fart1.ogg'), 50, 1)
		else
			playsound(src, "sound/misc/belt_click.ogg", 50, 1)
		RegisterSignal(to_buckle, COMSIG_MOVABLE_SET_LOC, .proc/maybe_unbuckle)

*/

	unbuckle()
		..()
		if(!src.occupant) return
		UnregisterSignal(occupant, COMSIG_MOVABLE_SET_LOC)

		var/mob/living/M = src.occupant
		var/mob/living/carbon/human/H = src.occupant

		M.end_chair_flip_targeting()

		if (istype(H) && H.standing_on)// == 1)
			M.pixel_y = 0
			H.ceilingreach = 0
			reset_anchored(M)
			M.buckled = null
			occupant.force_laydown_standup()
			src.occupant = null
			SPAWN_DBG(0.5 SECONDS)
				H.standing_on = null
				src.buckled = 0
		else if ((M.buckled))
			reset_anchored(M)
			M.buckled = null
			occupant.force_laydown_standup()
			src.occupant = null
			SPAWN_DBG(0.5 SECONDS)
				src.buckled = 0

		playsound(src, "sound/misc/belt_click.ogg", 50, 1)

	ex_act(severity) //shit's exploding, huh
		//unbuckle check
		for (var/mob/M in src.loc) //if you're standing, get off
			if (isstanding(M, src))
				user.visible_message("<span class='notice'><b>[M]</b> is knocked off of \the [src]!</span>", "<span class='notice'>You're knocked off of \the [src]!</span>")
				src.unstand()
				M.changeStatus("stunned", 8 SECONDS)
				M.changeStatus("weakened", 4 SECONDS)
			if (!isbucklestool(src)) //same if just sitting
				src.unbuckle()
		switch (severity)
			if (1.0)
				for (var/mob/M in src.loc)
					if (M.buckled == src)
						M.buckled = null
						src.occupant = null
				qdel(src)
				return
			if (2.0)
				if (prob(50))
					src.fall_over //knock on ass and hurt them
					for (var/mob/M in src.loc)
						if (M.buckled == src)
						M.buckled = null
						src.occupant = null
					qdel(src)
					return
				if (prob(20))
					src.fall_over
				if (prob(20))
					src.loose = 1
				return
			if (3.0)
				if (prob(5))
					for (var/mob/M in src.loc)
						if (M.buckled == src)
						M.buckled = null
						src.occupant = null
					qdel(src)
				if (prob(5))
					(src.fall_over)
				if (prob(5))
					src.loose = 1
				return
		return

	blob_act(var/power)
		if (prob(power * 2.5))
			for (var/mob/M in src.loc)
				if (M.buckled == src)
					M.buckled = null
					src.occupant = null
			qdel(src)

	disposing()
		for (var/mob/M in src.loc)
			if (M.buckled == src)
				M.buckled = null
				src.occupant = null
		if (has_butt)
			has_butt.set_loc(loc)
		has_butt = null
		..()
		return

	Move(atom/target)
		if(src.occupant?.loc != src.loc)
			src.unbuckle()
		. = ..()
		if(src.occupant?.loc != src.loc)
			src.unbuckle()

	Click(location,control,params)
		var/lpm = params2list(params)
		if(istype(usr, /mob/dead/observer) && !lpm["ctrl"] && !lpm["shift"] && !lpm["alt"])
			rotate()

#ifdef HALLOWEEN
			if (istype(usr.abilityHolder, /datum/abilityHolder/ghost_observer))
				var/datum/abilityHolder/ghost_observer/GH = usr.abilityHolder
				GH.change_points(3)
#endif
		else return ..()

	proc/rotate(var/face_dir = 0)
		if (rotatable)
			if (!face_dir)
				src.set_dir(turn(src.dir, 90))
			else
				src.set_dir(face_dir)

			if (src.dir == NORTH)
				src.layer = FLY_LAYER+1
			else
				src.layer = OBJ_LAYER
			if (occupant)
				var/mob/living/carbon/C = src.occupant
				C.set_dir(dir)
		return

	blue
		icon_state = "chair-b"

	yellow
		icon_state = "chair-y"

	red
		icon_state = "chair-r"

	green
		icon_state = "chair-g"

/* ========================================================== */
/* -------------------- Syndicate Chairs -------------------- */
/* ========================================================== */

/obj/stool/chair/syndicate
	desc = "That chair is giving off some bad vibes."
	comfort_value = -5
	event_handler_flags = USE_PROXIMITY | USE_FLUID_ENTER

	HasProximity(atom/movable/AM as mob|obj)
		if (ishuman(AM) && prob(40))
			src.visible_message("<span class='alert'>[src] trips [AM]!</span>", "<span class='alert'>You hear someone fall.</span>")
			AM:changeStatus("weakened", 2 SECONDS)
		return

/* ======================================================= */
/* -------------------- Folded Chairs -------------------- */
/* ======================================================= */

/obj/item/chair/folded //just realized there's no item/chair. is that legal???
	name = "chair"
	desc = "A folded chair. Good for smashing noggin-shaped things."
	icon = 'icons/obj/furniture/chairs.dmi'
	icon_state = "folded_chair"
	item_state = "folded_chair"
	w_class = W_CLASS_BULKY
	throwforce = 10
	flags = FPRINT | TABLEPASS | CONDUCT
	force = 5
	stamina_damage = 45
	stamina_cost = 21
	stamina_crit_chance = 10
	var/variety = null

	New()
		..()
		src.setItemSpecial(/datum/item_special/swipe)
		BLOCK_SETUP(BLOCK_LARGE)

	attack_self(mob/user as mob)
		if(cant_drop == 1)
			boutput(user, "You can't unfold the [src] when its attached to your arm!")
			return
		else
			var/obj/stool/chair/C = new/obj/stool/chair(user.loc)
			if (src.material)
				C.setMaterial(src.material)
			if (src.c_color)
				C.icon_state = src.c_color
			C.set_dir(user.dir)
			C.add_fingerprint(user)
			boutput(user, "You unfold [C].")
			user.drop_item()
			qdel(src)
			return

	attack(atom/target, mob/user as mob)
		var/oldcrit = src.stamina_crit_chance
		if(iswrestler(user))
			src.stamina_crit_chance = 100
		if (ishuman(target))
			playsound(src.loc, pick(sounds_punch), 100, 1)
		..()
		src.stamina_crit_chance = oldcrit

	stepladder
		name = "stepladder"
		desc = "A folded stepladder. Definitely beats dragging it."
		icon = 'icons/obj/fluid.dmi'
		icon_state = "ladder"
		item_state = "folded_chair"
		var/parts_type = /obj/item/furniture_parts/stepladder
		var/unfold_type = /obj/stool/stepladder
		var/variety = null
		w_class = W_CLASS_BULKY
		flags = FPRINT | TABLEPASS | CONDUCT
		force = 5
		stamina_damage = 45
		stamina_cost = 21
		stamina_crit_chance = 10

		attack_self(mob/user as mob)
			if(cant_drop == 1)
				boutput(user, "You can't unfold the [src] when its attached to your arm!")
				return
			else //unfold it
				var/obj/stool/stepladder/L = new src.unfold_type(user.loc)
				L.set_dir(user.dir)
				L.add_fingerprint(user)
				boutput(user, "You unfold [L].")
				user.drop_item()
				qdel(src)
				return

		wrestling
			name = "wrestling stepladder"
			desc = "A folded stepladder, ready to set up a hot beating."
			parts_type = /obj/item/furniture_parts/stepladder/wrestling
			unfold_type = /obj/stool/stepladder/wrestling
			throwforce = 10
			force = 10

/* ====================================================== */
/* -------------------- Comfy Chairs -------------------- */
/* ====================================================== */

/obj/stool/chair/comfy
	name = "comfy brown chair"
	desc = "This advanced seat commands authority and respect. Everyone is super envious of whoever sits in this chair."
	icon_state = "chair_comfy"
	comfort_value = 7
	foldable = 0
//	var/atom/movable/overlay/overl = null
	var/image/arm_image = null
	var/arm_icon_state = "arm"
	parts_type = /obj/item/furniture_parts/comfy_chair

	New()
		..()
		update_icon()

	rotate()
		set src in oview(1)
		set category = "Local"

		src.set_dir(turn(src.dir, 90))
		src.update_icon()
		if (occupant)
			var/mob/living/carbon/C = src.occupant
			C.set_dir(dir)
		return

	proc/update_icon()
		if (src.dir == NORTH)
			src.layer = FLY_LAYER+1
		else
			src.layer = OBJ_LAYER
			if ((src.dir == WEST || src.dir == EAST) && !src.arm_image)
				src.arm_image = image(src.icon, src.arm_icon_state)
				src.arm_image.layer = FLY_LAYER+1
				src.UpdateOverlays(src.arm_image, "arm")

	blue
		name = "comfy blue chair"
		icon_state = "chair_comfy-blue"
		arm_icon_state = "arm-blue"
		parts_type = /obj/item/furniture_parts/comfy_chair/blue

	red
		name = "comfy red chair"
		icon_state = "chair_comfy-red"
		arm_icon_state = "arm-red"
		parts_type = /obj/item/furniture_parts/comfy_chair/red

	green
		name = "comfy green chair"
		icon_state = "chair_comfy-green"
		arm_icon_state = "arm-green"
		parts_type = /obj/item/furniture_parts/comfy_chair/green

	yellow
		name = "comfy yellow chair"
		icon_state = "chair_comfy-yellow"
		arm_icon_state = "arm-yellow"
		parts_type = /obj/item/furniture_parts/comfy_chair/yellow

	purple
		name = "comfy purple chair"
		icon_state = "chair_comfy-purple"
		arm_icon_state = "arm-purple"
		parts_type = /obj/item/furniture_parts/comfy_chair/purple

/obj/stool/chair/comfy/throne_gold
	name = "golden throne"
	desc = "This throne commands authority and respect. Everyone is super envious of whoever sits in this chair."
	icon_state = "thronegold"
	arm_icon_state = "thronegold-arm"
	comfort_value = 7
	anchored = 0
	parts_type = /obj/item/furniture_parts/throne_gold

/* ======================================================== */
/* -------------------- Shuttle Chairs -------------------- */
/* ======================================================== */

/obj/stool/chair/comfy/shuttle
	name = "shuttle seat"
	desc = "Equipped with a safety buckle and a tray on the back for the person behind you to use!"
	icon_state = "shuttle_chair"
	arm_icon_state = "shuttle_chair-arm"
	buckles = 1
	comfort_value = 5
	deconstructable = 0
	parts_type = null

	red
		icon_state = "shuttle_chair-red"
	brown
		icon_state = "shuttle_chair-brown"
	green
		icon_state = "shuttle_chair-green"

/obj/stool/chair/comfy/shuttle/pilot
	name = "pilot's seat"
	desc = "Only the most important crew member gets to sit here. Everyone is super envious of whoever sits in this chair."
	icon_state = "shuttle_chair-pilot"
	arm_icon_state = "shuttle_chair-pilot-arm"
	comfort_value = 7

/* ================================================ */
/* ------------------- Wheelchairs ---------------- */
/* Chair on wheels, mobility aid.				    */
/* Climb/flip? Yes, dangerous. Ceiling? No.			*/
/* Buckle? No.										*/
/* Cuffable? No.									*/
/* Custom acts? None. Maybe amplifies prayer.		*/
/* ================================================ */

/obj/stool/chair/comfy/wheelchair
	name = "wheelchair"
	desc = "It's a chair that has wheels attached to it. Do I really have to explain this to you? Can you not figure this out on your own? Wheelchair. Wheel, chair. Chair that has wheels."
	icon_state = "wheelchair"
	arm_icon_state = "arm-wheelchair"
	anchored = 0
	comfort_value = 3
	buckles = 1
	buckle_move_delay = 1
	p_class = 2
	scoot_sounds = list("sound/misc/chair/office/scoot1.ogg", "sound/misc/chair/office/scoot2.ogg", "sound/misc/chair/office/scoot3.ogg", "sound/misc/chair/office/scoot4.ogg", "sound/misc/chair/office/scoot5.ogg")
	parts_type = /obj/item/furniture_parts/wheelchair
	mat_appearances_to_ignore = list("steel")
	mats = 15

	New()
		..()
		if (src.lying)
			animate_rest(src, !src.lying)
			src.p_class = initial(src.p_class) + src.lying // 2 while standing, 3 while lying

	update_icon()
		ENSURE_IMAGE(src.arm_image, src.icon, src.arm_icon_state)
		src.arm_image.layer = FLY_LAYER+1
		src.UpdateOverlays(src.arm_image, "arm")

	attack_hand(mob/user as mob)
		if (src.lying)
			user.visible_message("[user] sets [src] back on its wheels.",\
			"You set [src] back on its wheels.")
			src.lying = 0
			animate_rest(src, !src.lying)
			src.p_class = initial(src.p_class) + src.lying // 2 while standing, 3 while lying
			return
		else
			return ..()

	buckle_in(mob/living/to_buckle, mob/living/user, var/stand = 0)
		if (src.lying)
			return
		..()
		if (src.occupant == to_buckle)
			APPLY_MOVEMENT_MODIFIER(to_buckle, /datum/movement_modifier/wheelchair, src.type)

	unbuckle()
		if(src.occupant)
			REMOVE_MOVEMENT_MODIFIER(src.occupant, /datum/movement_modifier/wheelchair, src.type)
		return ..()

	set_loc(newloc)
		. = ..()
		unbuckle()

/* ================================================ */
/* ----------------- Wooden Chairs ---------------- */
/* Wooden Chair. That's all. Looks nice. Not comfy. */
/* Climb? Yep! Reaches Ceiling. Flipping: Yes		*/
/* Buckle? No.										*/
/* Cuffable? Yes.									*/
/* Custom acts? None. 								*/
/* ================================================ */

/obj/stool/chair/wooden
	name = "wooden chair"
	icon_state = "chair_wooden" // this sprite is bad I will fix it at some point
	stool_flags = STOOL_CUFFS
	comfort_value = 3
	foldable = 0
	anchored = 0
	parts_type = /obj/item/furniture_parts/wood_chair

	regal
		name = "regal chair"
		desc = "Much more comfortable than the average dining chair, and much more expensive."
		icon_state = "regalchair"
		comfort_value = 7
		parts_type = /obj/item/furniture_parts/wood_chair/regal

/* ================================================ */
/* ---------------------- Pews -------------------- */
/* Portable ladder for getting to high up stuff.    */
/* Climb? Yep! Reaches Ceiling. Flipping: lmao yes	*/
/* Buckle? No.										*/
/* Cuffable? No.									*/
/* Custom acts? None. Maybe amplifies prayer.		*/
/* ================================================ */

/obj/stool/chair/pew // pew pew
	name = "pew"
	desc = "It's like a bench, but more holy. No, not <i>holey</i>, <b>holy</b>. Like, godly, divine. That kinda thing.<br>Okay, it's actually kind of holey, too, now that you look at it closer."
	icon_state = "pew"
	anchored = 1
	rotatable = 0
	foldable = 0
	comfort_value = 2
	securable = 0
	parts_type = /obj/item/furniture_parts/bench/pew
	var/image/arm_image = null
	var/arm_icon_state = null

	New()
		..()
		if (arm_icon_state)
			src.update_icon()

	proc/update_icon()
		if (src.dir == NORTH)
			src.layer = FLY_LAYER+1
		else
			src.layer = OBJ_LAYER
			if ((src.dir == WEST || src.dir == EAST) && !src.arm_image)
				src.arm_image = image(src.icon, src.arm_icon_state)
				src.arm_image.layer = FLY_LAYER+1
				src.UpdateOverlays(src.arm_image, "arm")

	left
		icon_state = "pewL"
	center
		icon_state = "pewC"
	right
		icon_state = "pewR"

/obj/stool/chair/pew/fancy
	icon_state = "fpew"
	arm_icon_state = "arm-fpew"

	left
		icon_state = "fpewL"
		arm_icon_state = "arm-fpewL"
	center
		icon_state = "fpewC"
		arm_icon_state = null
	right
		icon_state = "fpewR"
		arm_icon_state = "arm-fpewR"

/* ================================================ */
/* ------------------- Couches -------------------- */
/* Nice place to sit down. Deep cushions.		    */
/* Climb? Yep! Doesn't reach ceiling. Flipping: Yep.*/
/* Buckle? No, no buckles. It's a COUCH.			*/
/* Cuffable? HOW DO YOU CUFF TO A COUCH.			*/
/* Custom acts? Search for treasure.				*/
/* ================================================ */

/obj/stool/chair/couch
	name = "comfy brown couch"
	desc = "You've probably lost some space credits in these things before."
	icon_state = "chair_couch-brown"
	rotatable = 0
	foldable = 0
	var/damaged = 0
	comfort_value = 5
	deconstructable = 0
	securable = 0
	var/max_uses = 0 // The maximum amount of time one can try to look under the cushions for items.
	var/spawn_chance = 0 // How likely is this couch to spawn something?
	var/last_use = 0 // To prevent spam.
	var/time_between_uses = 400 // The default time between uses: 4 seconds.
	var/list/items = list (/obj/item/device/light/zippo,
	/obj/item/wrench,
	/obj/item/device/multitool,
	/obj/item/toy/plush/small/buddy,
	/obj/item/toy/plush/small/stress_ball,
	/obj/item/paper/lunchbox_note,
	/obj/item/plant/herb/cannabis/spawnable,
	/obj/item/reagent_containers/food/snacks/candy/candyheart,
	/obj/item/bananapeel,
	/obj/item/reagent_containers/food/snacks/lollipop/random_medical,
	/obj/item/spacecash/random/small,
	/obj/item/spacecash/random/tourist,
	/obj/item/spacecash/buttcoin)

	New()
		..()
		max_uses = rand(0, 2) // Losing things in a couch is hard.
		spawn_chance = rand(1, 20)

		if (prob(10)) //time to flail
			items.Add(/obj/critter/meatslinky)

		if (prob(1))
			desc = "A vague feeling of loss emanates from this couch, as if it is missing a part of itself. A global list of couches, perhaps."

	disposing()
		..()

	proc/damage(severity)
		if(severity > 1 && damaged < 2)
			damaged += 2
			overlays += image('icons/obj/objects.dmi', "couch-tear")
		else if(damaged < 1)
			damaged += 1
			overlays += image('icons/obj/objects.dmi', "couch-rip")

	attack_hand(mob/user as mob)
		if (!user) return
		if (damaged || occupant) return ..()

		user.lastattacked = src

		playsound(src.loc, "rustle", 66, 1, -5) // todo: find a better sound.

		if (max_uses > 0 && ((last_use + time_between_uses) < world.time) && prob(spawn_chance))

			var/something = pick(items)

			if (ispath(something))
				var/thing = new something(src.loc)
				user.put_in_hand_or_drop(thing)
				if (istype(thing, /obj/critter/meatslinky)) //slink slink
					user.emote("scream")
					random_brute_damage(user, 10)
					user.visible_message("<span class='notice'><b>[user.name]</b> rummages through the seams and behind the cushions of [src] and pulls [his_or_her(user)] hand out in pain! \An [thing] slithers out of \the [src]!</span>",\
					"<span class='notice'>You rummage through the seams and behind the cushions of [src] and your hand gets bit by \an [thing]!</span>")
				else
					user.visible_message("<span class='notice'><b>[user.name]</b> rummages through the seams and behind the cushions of [src] and pulls \an [thing] out of it!</span>",\
					"<span class='notice'>You rummage through the seams and behind the cushions of [src] and you find \an [thing]!</span>")
				last_use = world.time
				max_uses--

		else if (max_uses <= 0)
			user.visible_message("<span class='notice'><b>[user.name]</b> rummages through the seams and behind the cushions of [src] and pulls out absolutely nothing!</span>",\
			"<span class='notice'>You rummage through the seams and behind the cushions of [src] and pull out absolutely nothing!</span>")
		else
			user.visible_message("<span class='notice'><b>[user.name]</b> rummages through the seams and behind the cushions of [src]!</span>",\
			"<span class='notice'>You rummage through the seams and behind the cushions of [src]!</span>")

	blue
		name = "comfy blue couch"
		icon_state = "chair_couch-blue"

	red
		name = "comfy red couch"
		icon_state = "chair_couch-red"

	green
		name = "comfy green couch"
		icon_state = "chair_couch-green"

	yellow
		name = "comfy yellow couch"
		icon_state = "chair_couch-yellow"

	purple
		name = "comfy purple couch"
		icon_state = "chair_couch-purple"

/* ================================================ */
/* ---------------- Office Chairs ----------------- */
/* Comfy wheeled chairs							    */
/* Climb/flip? Probably fall on ass! Ceiling reach.	*/
/* Buckle? No, no buckles. It's an office chair.	*/
/* Cuffable? Sure.									*/
/* Custom acts? Maybe fiddling with controls.		*/
/* ================================================ */

/obj/stool/chair/office
	name = "office chair"
	desc = "Hey, you remember spinning around on one of these things as a kid!"
	icon_state = "office_chair"
	stool_flags = STOOL_CUFFS
	comfort_value = 4
	foldable = 0
	anchored = 0
	casters = 1
	casterslocked = 1 //try starting with them locked, see what happens
	buckle_move_delay = 3
	parts_type = /obj/item/furniture_parts/office_chair
	scoot_sounds = list( 'sound/misc/chair/office/scoot1.ogg', 'sound/misc/chair/office/scoot2.ogg', 'sound/misc/chair/office/scoot3.ogg', 'sound/misc/chair/office/scoot4.ogg', 'sound/misc/chair/office/scoot5.ogg' )

	red
		icon_state = "office_chair_red"
		parts_type = /obj/item/furniture_parts/office_chair/red

	green
		icon_state = "office_chair_green"
		parts_type = /obj/item/furniture_parts/office_chair/green

	blue
		icon_state = "office_chair_blue"
		parts_type = /obj/item/furniture_parts/office_chair/blue

	yellow
		icon_state = "office_chair_yellow"
		parts_type = /obj/item/furniture_parts/office_chair/yellow

	purple
		icon_state = "office_chair_purple"
		parts_type = /obj/item/furniture_parts/office_chair/purple

	syndie
		icon_state = "syndiechair"
		parts_type = null

	//if you're sitting in it and you're not cuffed, click to toggle casters.
	//if you want to get up, make sure casters are locked.
	//same behavior as buckles

	attackby(obj/item/W as obj, mob/user as mob)
		else if (isweldingtool(W) && src.securable && src.casters)
			src.toggle_weld(user)
			return
		else
			return ..()

	proc/toggle_casters(mob/user as mob) //doesn't anchor
		if (user)
			user.visible_message("<b>[user]</b> [src.casterslocked ? "unlocks" : "locks"] the casters of [src].[istype(src.loc, /turf/space) ? " It doesn't do much, though, since [src] is in space and all." : null]")
		playsound(src, "sound/items/pickup_3.ogg", 100, 1)
		src.casterslocked = !(src.casterslocked)
		return

	//rolling chairs aren't actually secure, after all
	proc/toggle_weld(mob/user as mob) //does anchor
		if (istype(get_turf(src), /turf/space)) //it's in space
			if (user)
				user.show_text("What exactly are you gunna weld [src] to?", "red")
				return
		if (user)
			if (src.casters)
				user.visible_message("<b>[user]</b> [src.anchored ? "unwelds" : "welds"] the casters of [src][istype(src.loc, /turf/space) ? " It doesn't do much, though, since [src] is in space and all." : "to the floor."].")
			else
				user.visible_message("<b>[user]</b> [src.anchored ? "unwelds [src]'s casters from" : "welds [src]'s casters to"] the floor.")
		if (src.welded)
			playsound(src, "sound/items/Welder2.ogg", 100, 1)
		else
			playsound(src, "sound/items/Welder1.ogg", 100, 1)
		src.welded = !(src.welded)
		src.anchored = src.welded
		src.p_class = src.welded ? 3 : 2
		return

/* ================================================ */folds_into
/* ----------------Stepladders -------------------- */
/* Portable ladder for getting to high up stuff.    */
/* Climb? Yep! Reaches Ceiling. Flipping: maybe.	*/
/* Buckle? No, no buckles. It's a stepstool.		*/
/* Cuffable? No, how would that work?				*/
/* Custom acts? None..								*/
/* ================================================ */

/obj/stool/stepladder //this can be cleaned up from some lingering buckle stuffs and other checks. also forces looking up
	name = "stepladder"
	desc = "A small freestanding ladder that lets you peek your head up at the ceiling. Mostly for changing lightbulbs. Not for wrestling."
	icon = 'icons/obj/fluid.dmi'
	icon_state = "ladder"
	stool_flags = STOOL_STEP
	foldable = 1
	casters = 1
	securable = 1
	anchored = 0
	density = 0
	stable = 1
	ceilingreach = 1
	flags = FPRINT | FLUID_SUBMERGE
	throwforce = 15
	parts_type = /obj/item/furniture_parts/stepladder
	fold_type = /obj/item/folded/stepladder

	//click and drag to get on no matter what intent

	wrestling //this can be cleaned up from some lingering buckle stuffs and other checks. also forces looking up
		name = "stepladder"
		desc = "A small freestanding ladder that lets you lay the hurt down on your enemies. Totally for wrestling. Not for changing lightbulbs."
		icon = 'icons/obj/fluid.dmi'
		icon_state = "ladder"
		stool_flags = STOOL_WRESTLING
		casters = 0 //no wheels
		securable = 0
		density = 1 //gets in the way
		parts_type = /obj/item/furniture_parts/stepladder/wrestling
		fold_type = /obj/item/folded/stepladder/wrestling

		New()
		src.p_class = 3 // no wheels, only scrapes
		..()

/* ================================================ */
/* ----------------Electric Chair ----------------- */
/* Zaps whoever's in it if it's got power/cable.    */
/* Climb? Yep! Reaches Ceiling. Flipping: YES.		*/
/* Buckle? Yep!										*/
/* Cuffable? Yep!									*/
/* Some controls. Only here.						*/
/* ================================================ */

/obj/stool/chair/e_chair
	name = "electrified chair"
	desc = "A chair that has been modified to conduct current with over 2000 volts, enough to kill a human nearly instantly."
	icon_state = "e_chair0"
	foldable = 0
	var/on = 0
	var/obj/item/assembly/shock_kit/part1 = null
	var/last_time = 1
	var/lethal = 0
	var/image/image_belt = null
	cuffable = 1
	comfort_value = -3
	securable = 0

	New()
		..()
		SPAWN_DBG(2 SECONDS)
			if (src)
				if (!(src.part1 && istype(src.part1)))
					src.part1 = new /obj/item/assembly/shock_kit(src)
					src.part1.master = src
				src.update_icon()
		return

	attackby(obj/item/W as obj, mob/user as mob)
		if (iswrenchingtool(W))
			var/obj/stool/chair/C = new /obj/stool/chair(get_turf(src))
			if (src.material)
				C.setMaterial(src.material)
			playsound(src.loc, "sound/items/Ratchet.ogg", 50, 1)
			C.set_dir(src.dir)
			if (src.part1)
				src.part1.set_loc(get_turf(src))
				src.part1.master = null
				src.part1 = null
			qdel(src)
			return

	verb/controls()
		set src in oview(1)
		set category = "Local"

		src.control_interface(usr)

	// Seems to be the only way to get this stuff to auto-refresh properly, sigh (Convair880).
	proc/control_interface(mob/user as mob)
		if (!user.hasStatus("handcuffed") && isalive(user))
			src.add_dialog(user)

			var/dat = ""

			var/area/A = get_area(src)
			if (!isarea(A) || !A.powered(EQUIP))
				dat += "\n<font color='red'>ERROR:</font> No power source detected!</b>"
			else
				dat += {"<A href='?src=\ref[src];on=1'>[on ? "Switch Off" : "Switch On"]</A><BR>
				<A href='?src=\ref[src];lethal=1'>[lethal ? "<font color='red'>Lethal</font>" : "Nonlethal"]</A><BR><BR>
				<A href='?src=\ref[src];shock=1'>Shock</A><BR>"}

			user.Browse("<TITLE>Electric Chair</TITLE><b>Electric Chair</b><BR>[dat]", "window=e_chair;size=180x180")

			onclose(user, "e_chair")
		return

	Topic(href, href_list)
		if (usr.getStatusDuration("stunned") || usr.getStatusDuration("weakened") || usr.stat || usr.restrained()) return
		if (!in_interact_range(src, usr)) return

		if (href_list["on"])
			toggle_active()
		else if (href_list["lethal"])
			toggle_lethal()
		else if (href_list["shock"])
			if (src.occupant)
				// The log entry for remote signallers can be found in item/assembly/shock_kit.dm (Convair880).
				logTheThing("combat", usr, src.occupant, "activated an electric chair (setting: [src.lethal ? "lethal" : "non-lethal"]), shocking [constructTarget(src.occupant,"combat")] at [log_loc(src)].")
			shock(lethal)

		src.control_interface(usr)
		src.add_fingerprint(usr)
		return

	proc/toggle_active()
		src.on = !(src.on)
		src.update_icon()
		return src.on

	proc/toggle_lethal()
		src.lethal = !(src.lethal)
		src.update_icon()
		return

	proc/update_icon()
		src.icon_state = "e_chair[src.on]"
		if (!src.image_belt)
			src.image_belt = image(src.icon, "e_chairo[src.on][src.lethal]", layer = FLY_LAYER + 1)
			src.UpdateOverlays(src.image_belt, "belts")
			return
		src.image_belt.icon_state = "e_chairo[src.on][src.lethal]"
		src.UpdateOverlays(src.image_belt, "belts")

	// Options:      1) place the chair anywhere in a powered area (fixed shock values),
	// (Convair880)  2) on top of a powered wire (scales with engine output).
	proc/get_connection()
		var/turf/T = get_turf(src)
		if (!istype(T, /turf/simulated/floor))
			return 0

		for (var/obj/cable/C in T)
			return C.netnum

		return 0

	proc/get_gridpower()
		var/netnum = src.get_connection()

		if (netnum)
			var/datum/powernet/PN
			if (powernets && powernets.len >= netnum)
				PN = powernets[netnum]
				return PN.avail

		return 0

	proc/shock(lethal)
		if (!src.on)
			return
		if ((src.last_time + 50) > world.time)
			return
		src.last_time = world.time

		// special power handling
		var/area/A = get_area(src)
		if (!isarea(A))
			return
		if (!A.powered(EQUIP))
			return
		A.use_power(EQUIP, 5000)
		A.updateicon()

		for (var/mob/M in AIviewers(src, null))
			M.show_message("<span class='alert'>The electric chair went off!</span>", 3)
			if (lethal)
				playsound(src.loc, "sound/effects/electric_shock.ogg", 50, 0)
			else
				playsound(src.loc, "sound/effects/sparks4.ogg", 50, 0)

		if (src.occupant && ishuman(src.occupant))
			var/mob/living/carbon/human/H = src.occupant

			if (src.lethal)
				var/net = src.get_connection() // Are we wired-powered (Convair880)?
				var/power = src.get_gridpower()
				if (!net || (net && (power < 2000000)))
					H.shock(src, 2000000, "chest", 0.3, 1) // Nope or not enough juice, use fixed values instead (around 80 BURN per shock).
				else
					//DEBUG_MESSAGE("Shocked [H] with [power]")
					src.electrocute(H, 100, net, 1) // We are, great. Let that global proc calculate the damage.
			else
				H.shock(src, 2500, "chest", 1, 1)
				H.changeStatus("stunned", 10 SECONDS)

			if (ticker?.mode && istype(ticker.mode, /datum/game_mode/revolution))
				if ((H.mind in ticker.mode:revolutionaries) && !(H.mind in ticker.mode:head_revolutionaries) && prob(66))
					ticker.mode:remove_revolutionary(H.mind)

		A.updateicon()
		return
