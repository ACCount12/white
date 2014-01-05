/obj/machinery/igniter/attack_ai(mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/igniter/attack_paw(mob/user as mob)
	if ((ticker && ticker.mode.name == "monkey"))
		return src.attack_hand(user)
	return

/obj/machinery/igniter/attack_hand(mob/user as mob)
	if(..())
		return
	add_fingerprint(user)

	use_power(50)
	src.on = !( src.on )
	src.icon_state = text("igniter[]", src.on)
	return

/obj/machinery/igniter/process()
	if (src.on && !(stat & NOPOWER) )
		var/turf/location = src.loc
		if (isturf(location))
			location.hotspot_expose(6000,500,1)
	return 1

/obj/machinery/igniter/New()
	..()
	icon_state = "igniter[on]"

/obj/machinery/igniter/power_change()
	if(!( stat & NOPOWER) )
		icon_state = "igniter[src.on]"
	else
		icon_state = "igniter0"

// Wall mounted remote-control igniter.

/obj/machinery/sparker
	name = "Wall-mounted Igniter"
	desc = "A wall-mounted ignition device."
	icon = 'stationobjs.dmi'
	icon_state = "migniter"
	var/id = null
	var/disable = 0
	var/last_spark = 0
	var/base_state = "migniter"
	anchored = 1

/obj/machinery/sparker/New()
	..()

/obj/machinery/sparker/power_change()
	if ( powered() && disable == 0 )
		stat &= ~NOPOWER
		icon_state = "[base_state]"
		src.ul_SetLuminosity(2)
	else
		stat |= ~NOPOWER
		icon_state = "[base_state]-p"
		src.ul_SetLuminosity(0)

/obj/machinery/sparker/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if (istype(W, /obj/item/weapon/screwdriver))
		add_fingerprint(user)
		src.disable = !src.disable
		if (src.disable)
			user.visible_message("\red [user] has disabled the [src]!", "\red You disable the connection to the [src].")
			icon_state = "[base_state]-d"
		if (!src.disable)
			user.visible_message("\red [user] has reconnected the [src]!", "\red You fix the connection to the [src].")
			if(src.powered())
				icon_state = "[base_state]"
			else
				icon_state = "[base_state]-p"

/obj/machinery/sparker/attack_ai()
	if (src.anchored)
		return src.ignite()
	else
		return

/obj/machinery/sparker/proc/ignite()
	if (!(powered()))
		return

	if ((src.disable) || (src.last_spark && world.time < src.last_spark + 50))
		return


	flick("[base_state]-spark", src)
	var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
	s.set_up(2, 1, src)
	s.start()
	src.last_spark = world.time
	use_power(1000)
	var/turf/location = src.loc
	if (isturf(location))
		location.hotspot_expose(6000,500,1)
	return 1