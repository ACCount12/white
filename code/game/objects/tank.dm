/obj/item/weapon/tank
	name = "tank"
	icon = 'tank.dmi'

	var/datum/gas_mixture/air_contents = null
	var/distribute_pressure = ONE_ATMOSPHERE
	flags = FPRINT | CONDUCT
	slot_flags = SLOT_BACK

	pressure_resistance = ONE_ATMOSPHERE*5

	force = 5.0
	throwforce = 10.0
	throw_speed = 1
	throw_range = 4


/obj/item/weapon/tank/blob_act()
	if(prob(25))
		var/turf/location = src.loc
		if (!istype(location, /turf))
			del(src)

		if(src.air_contents)
			location.assume_air(air_contents)

		del(src)

/obj/item/weapon/tank/attack_self(mob/user as mob)
	user.set_machine(src)
	if (!src.air_contents)
		return

	var/using_internal
	if(istype(loc,/mob/living/carbon))
		var/mob/living/carbon/location = loc
		if(location.internal==src)
			using_internal = 1

	var/message = {"
<b>Tank</b><BR>
<FONT color='blue'><b>Tank Pressure:</b> [air_contents.return_pressure()]</FONT><BR>
<BR>
<b>Mask Release Pressure:</b> <A href='?src=\ref[src];dist_p=-10'>-</A> <A href='?src=\ref[src];dist_p=-1'>-</A> [distribute_pressure] <A href='?src=\ref[src];dist_p=1'>+</A> <A href='?src=\ref[src];dist_p=10'>+</A><BR>
<b>Mask Release Valve:</b> <A href='?src=\ref[src];stat=1'>[using_internal?("Open"):("Closed")]</A>
"}
	user << browse(message, "window=tank;size=600x300")
	onclose(user, "tank")
	return

/obj/item/weapon/tank/Topic(href, href_list)
	..()
	if (usr.stat|| usr.restrained())
		return
	if (src.loc == usr)
		usr.set_machine(src)
		if (href_list["dist_p"])
			var/cp = text2num(href_list["dist_p"])
			src.distribute_pressure += cp
			src.distribute_pressure = min(max(round(src.distribute_pressure), 0), 3*ONE_ATMOSPHERE)
		if (href_list["stat"])
			if(istype(loc,/mob/living/carbon))
				var/mob/living/carbon/location = loc
				if(location.internal == src)
					location.internal = null
					location.internals.icon_state = "internal0"
					usr << "\blue You close the tank release valve."
				else
					if(location.wear_mask && (location.wear_mask.flags & MASKINTERNALS))
						location.internal = src
						usr << "\blue You open the tank valve."
					else
						usr << "\blue The valve immediately closes."

		src.add_fingerprint(usr)
		for(var/mob/M in viewers(1, src.loc))
			if ((M.client && M.machine == src))
				src.attack_self(M)
	else
		usr << browse(null, "window=tank")
		return
	return

/obj/item/weapon/tank
	remove_air(amount)
		return air_contents.remove(amount)

	return_air()
		return air_contents

	assume_air(datum/gas_mixture/giver)
		air_contents.merge(giver)

		check_status()
		return 1

	proc/remove_air_volume(volume_to_return)
		if(!air_contents)
			return null

		var/tank_pressure = air_contents.return_pressure()
		if(tank_pressure < distribute_pressure)
			distribute_pressure = tank_pressure

		var/moles_needed = distribute_pressure*volume_to_return/(R_IDEAL_GAS_EQUATION*air_contents.temperature)

		return remove_air(moles_needed)

	process()
		//Allow for reactions
		air_contents.react()
		check_status()

	var/integrity = 3
	proc/check_status()
		//Handle exploding, leaking, and rupturing of the tank

		if(!air_contents)
			return 0

		var/pressure = air_contents.return_pressure()
		if(pressure > TANK_FRAGMENT_PRESSURE)
			//world << "\blue[x],[y] tank is exploding: [pressure] kPa"
			//Give the gas a chance to build up more pressure through reacting
			air_contents.react()
			air_contents.react()
			air_contents.react()
			pressure = air_contents.return_pressure()

			var/range = (pressure-TANK_FRAGMENT_PRESSURE)/TANK_FRAGMENT_SCALE
			range = min(range, 14)		// was 8
			var/turf/epicenter = get_turf(loc)


			//world << "\blue Exploding Pressure: [pressure] kPa, intensity: [range]"
			if(epicenter)
				explosion(epicenter, round(range*0.24), round(range*0.5), round(range), round(range*1.5), 1)
				del(src)
				return
			else
				message_admins("Whoops a bomb fucked up, [loc]")
				del(src)
				return


		else if(pressure > TANK_RUPTURE_PRESSURE)
			//world << "\blue[x],[y] tank is rupturing: [pressure] kPa, integrity [integrity]"
			if(integrity <= 0)
				loc.assume_air(air_contents)
				//TODO: make pop sound
				del(src)
			else
				integrity--

		else if(pressure > TANK_LEAK_PRESSURE)
			//world << "\blue[x],[y] tank is leaking: [pressure] kPa, integrity [integrity]"
			if(integrity <= 0)
				var/datum/gas_mixture/leaked_gas = air_contents.remove_ratio(0.25)
				loc.assume_air(leaked_gas)
			else
				integrity--

		else if(integrity < 3)
			integrity++

/obj/item/weapon/tank/attack(mob/M as mob, mob/user as mob)
	..()
	if ((prob(30) && M.stat < 2))
		var/mob/living/carbon/human/H = M

// ******* Check

		if ((istype(H, /mob/living/carbon/human) && istype(H, /obj/item/clothing/head) && H.flags & 8 && prob(80)))
			M << "\red The helmet protects you from being hit hard in the head!"
			return
		var/time = rand(2, 6)
		if (prob(90))
			if (M.paralysis < time)
				M.paralysis = time
		else
			if (M.stunned < time)
				M.stunned = time
		if(M.stat != 2)	M.stat = 1
		for(var/mob/O in viewers(M, null))
			if ((O.client && !( O.blinded )))
				O << text("\red <B>[] has been knocked unconscious!</B>", M)
	return

/obj/item/weapon/tank/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if ((istype(W, /obj/item/device/analyzer) || (istype(W, /obj/item/device/pda))) && get_dist(user, src) <= 1)

		for (var/mob/O in viewers(user, null))
			O << "\red [user] has used [W] on \icon[icon] [src]"

		var/pressure = air_contents.return_pressure()

		var/total_moles = air_contents.total_moles()

		user << "\blue Results of analysis of \icon[icon]"
		if(total_moles>0)
			var/o2_concentration = air_contents.oxygen/total_moles
			var/n2_concentration = air_contents.nitrogen/total_moles
			var/co2_concentration = air_contents.carbon_dioxide/total_moles
			var/plasma_concentration = air_contents.toxins/total_moles

			var/unknown_concentration =  1-(o2_concentration+n2_concentration+co2_concentration+plasma_concentration)

			user << "\blue Pressure: [round(pressure,0.1)] kPa"
			user << "\blue Nitrogen: [round(n2_concentration*100)]%"
			user << "\blue Oxygen: [round(o2_concentration*100)]%"
			user << "\blue CO2: [round(co2_concentration*100)]%"
			user << "\blue Plasma: [round(plasma_concentration*100)]%"
			if(unknown_concentration>0.01)
				user << "\red Unknown: [round(unknown_concentration*100)]%"
			user << "\blue Temperature: [round(air_contents.temperature-T0C)]&deg;C"
		else
			user << "\blue Tank is empty!"

		src.add_fingerprint(user)
	if(istype(W, /obj/item/device/assembly_holder))
		bomb_assemble(W,user)
	return

/obj/item/weapon/tank/New()
	..()

	src.air_contents = new /datum/gas_mixture()
	src.air_contents.volume = 70 //liters
	src.air_contents.temperature = T20C

	processing_items.Add(src)

	return

/obj/item/weapon/tank/Del()
	if(air_contents)
		del(air_contents)

	processing_items.Remove(src)

	..()

/obj/item/weapon/tank/examine()
	..()
	var/obj/item/weapon/icon = src
	if (istype(src.loc, /obj/item/device))
		icon = src.loc

		var/celsius_temperature = src.air_contents.temperature-T0C
		var/descriptive

		if (celsius_temperature < 20)
			descriptive = "cold"
		else if (celsius_temperature < 40)
			descriptive = "room temperature"
		else if (celsius_temperature < 80)
			descriptive = "lukewarm"
		else if (celsius_temperature < 100)
			descriptive = "warm"
		else if (celsius_temperature < 300)
			descriptive = "hot"
		else
			descriptive = "furiously hot"

		usr << text("\blue The \icon[] feels []", icon, descriptive)

	return


/obj/item/weapon/tank/air
	name = "air tank"
	desc = "Mixed anyone?"
	icon_state = "oxygen"

/obj/item/weapon/tank/air/New()
	..()
	src.air_contents.oxygen = (6*ONE_ATMOSPHERE)*src.air_contents.volume/(R_IDEAL_GAS_EQUATION*T20C) * O2STANDARD
	src.air_contents.nitrogen = (6*ONE_ATMOSPHERE)*src.air_contents.volume/(R_IDEAL_GAS_EQUATION*T20C) * N2STANDARD
	return


/obj/item/weapon/tank/oxygen
	name = "oxygen tank"
	desc = "A tank of oxygen."
	icon_state = "oxygen"

/obj/item/weapon/tank/oxygen/New()
	..()
	src.air_contents.oxygen = (6*ONE_ATMOSPHERE)*src.air_contents.volume/(R_IDEAL_GAS_EQUATION*T20C)
	return

/obj/item/weapon/tank/oxygen/yellow
	desc = "A tank of oxygen, this one is yellow."
	icon_state = "oxygen_f"

/obj/item/weapon/tank/oxygen/red
	desc = "A tank of oxygen, this one is red."
	icon_state = "oxygen_fr"


/obj/item/weapon/tank/emergency_oxygen
	name = "emergency oxygen tank"
	icon_state = "emergency"
	slot_flags = SLOT_BELT
	w_class = 2
	force = 7.0

	attackby(var/obj/item/weapon/tank/emergency_oxygen/T, mob/user as mob)
		if(!istype(T))
			..()
			return
		if(istype(src, /obj/item/weapon/tank/emergency_oxygen/double)) return
		if(type != T.type) return

		var/obj/item/weapon/tank/emergency_oxygen/double/D
		if(istype(T, /obj/item/weapon/tank/emergency_oxygen/engi))
			D = new /obj/item/weapon/tank/emergency_oxygen/double/engi
		else
			D = new /obj/item/weapon/tank/emergency_oxygen/double

		D.loc = user
		if (user.r_hand == T)
			user.u_equip(T)
			user.r_hand = D
		else
			user.u_equip(T)
			user.l_hand = D
		D.layer = 20
		//user << "You connect the emergency oxygen tanks together."
		release()
		T.release()
		user.update_clothing()
		del(T)
		del(src)


/obj/item/weapon/tank/emergency_oxygen/New()
	..()
	src.air_contents.volume = 15 //liters
	src.air_contents.oxygen = (2*ONE_ATMOSPHERE)*src.air_contents.volume/(R_IDEAL_GAS_EQUATION*T20C)
	return

/obj/item/weapon/tank/emergency_oxygen/engi
	icon_state = "emergency_engi"
	item_state = "emergency_engi"
/obj/item/weapon/tank/emergency_oxygen/engi/New()
	..()
	src.air_contents.volume = 25 //liters
	src.air_contents.oxygen = (2*ONE_ATMOSPHERE)*src.air_contents.volume/(R_IDEAL_GAS_EQUATION*T20C)
	return


/obj/item/weapon/tank/emergency_oxygen/double
	name = "double emergency oxygen tank"
	icon_state = "emergency_double"
	item_state = "emergency"
	slot_flags = SLOT_BELT
	w_class = 2.5
	force = 6
/obj/item/weapon/tank/emergency_oxygen/double/New()
	..()
	src.air_contents.volume = 30 //liters
	src.air_contents.oxygen = 0
	return


/obj/item/weapon/tank/emergency_oxygen/double/engi
	icon_state = "emergency_double_engi"
	item_state = "emergency_engi"
/obj/item/weapon/tank/emergency_oxygen/double/engi/New()
	..()
	src.air_contents.volume = 50 //liters
	return


/obj/item/weapon/tank/anesthetic
	name = "anesthetic tank"
	desc = "A tank with an N2O/O2 gas mix."
	icon_state = "anesthetic"

/obj/item/weapon/tank/anesthetic/New()
	..()

	src.air_contents.oxygen = (3*ONE_ATMOSPHERE)*70/(R_IDEAL_GAS_EQUATION*T20C) * O2STANDARD

	var/datum/gas/sleeping_agent/trace_gas = new()
	trace_gas.moles = (3*ONE_ATMOSPHERE)*70/(R_IDEAL_GAS_EQUATION*T20C) * N2STANDARD

	src.air_contents.trace_gases += trace_gas
	return


/obj/item/weapon/tank/plasma
	name = "plasma tank"
	desc = "Contains dangerous plasma. Do not inhale. Warning: extremely flammable."
	icon_state = "plasma"

/obj/item/weapon/tank/plasma/New()
	..()

	src.air_contents.toxins = (3*ONE_ATMOSPHERE)*70/(R_IDEAL_GAS_EQUATION*T20C)
	return