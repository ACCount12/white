/mob/living/silicon/ai/Login()
	..()
	for(var/S in client.screen)
		del(S)

/*	for(var/obj/effect/rune/rune in world)
		var/image/blood = image(loc = rune)
		blood.override = 1
		client.images += blood*/

	flash = new /obj/effect/screen( null )
	flash.icon_state = "blank"
	flash.name = "flash"
	flash.screen_loc = "1,1 to 15,15"
	flash.layer = 17
	blind = new /obj/effect/screen( null )
	blind.icon_state = "black"
	blind.name = " "
	blind.screen_loc = "1,1 to 15,15"
	blind.layer = 0
	client.screen += list( blind, flash )

	if(stat != DEAD)
		for(var/obj/machinery/ai_status_display/O in world) //change status
			O.mode = 1
			O.emotion = "Neutral"