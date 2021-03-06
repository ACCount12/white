/datum/game_mode/nuclear
	name = "nuclear emergency"
	config_tag = "nuclear"
	enabled = 1

	var/finished = 0
	var/nuke_detonated = 0 //Has the nuke gone off?
	var/agents_possible = 0 //If we ever need more syndicate agents.

	var/list/synd_spawns = list()
	var/list/disk_spawns = list()

	uplink_items = {"
/obj/item/weapon/storage/box/syndie_kit/imp_freedom:2:Freedom Implant, with injector;
/obj/item/weapon/storage/box/syndie_kit/imp_compress:5:Compressed matter implant, with injector;
/obj/item/weapon/storage/box/syndie_kit/imp_explosive:6:Explosive implant, with injector;
/obj/item/device/hacktool:3:Hacktool;
/obj/item/weapon/storage/toolbox/syndicate:1:Fully Loaded Toolbox;
/obj/item/weapon/soap/syndie:1:Syndicate Soap;
/obj/item/clothing/shoes/syndigaloshes:1:No-Slip Syndicate Shoes;
/obj/item/device/encryptionkey/syndicate:1:Binary Encryption Key;
/obj/item/clothing/under/chameleon:2:Chameleon Jumpsuit;
/obj/item/weapon/gun/projectile/revolver:6:Revolver;
/obj/item/ammo_magazine/box/a357:3:Revolver Ammo;
/obj/item/weapon/card/emag:2:Cryptographic Sequencer;
/obj/item/weapon/card/id/syndicate:1:Fake ID;
/obj/item/clothing/glasses/thermal:4:Thermal Glasses;
/obj/item/weapon/storage/box/grenades/emp:4:Box of EMP grenades;
/obj/item/device/powersink:5:Power sink;
/obj/item/weapon/cartridge/syndicate:2:Detomatix PDA cart;
/obj/item/device/chameleon:4:Chameleon projector;
/obj/item/weapon/melee/energy/sword:5:Energy sword;
/obj/item/weapon/pen/deathpen:4:Death pen;
/obj/item/weapon/gun/energy/crossbow:5:Energy crossbow;
/obj/item/clothing/mask/gas/voice:3:Voice changer;
/obj/item/weapon/aiModule/freeform:3:Freeform AI module;
/obj/item/weapon/syndie/c4explosive:4:Low power explosive charge;
/obj/item/weapon/syndie/c4explosive/heavy:7:High (!) power explosive charge;
/obj/item/weapon/reagent_containers/pill/cyanide:2:Cyanide Pill
	"}

	uplink_uses = 0

/datum/game_mode/nuclear/announce()
	world << "<B>The current game mode is - Nuclear Emergency!</B>"
//	world << "<B>A [syndicate_name()] Strike Force is approaching [station_name()]!</B>"
//	world << "A nuclear explosive was being transported by NanoTrasen to a military base. The transport ship mysteriously lost contact with Space Traffic Control (STC). About that time a strange disk was discovered around [station_name()]. It was identified by NanoTrasen as a nuclear auth. disk and now Syndicate Operatives have arrived to retake the disk and detonate NSV Luna! Also, most likely Syndicate star ships are in the vicinity so take care not to lose the disk!\n<B>Syndicate</B>: Reclaim the disk and detonate the nuclear bomb anywhere on Luna.\n<B>Personnel</B>: Hold the disk and <B>escape with the disk</B> on the shuttle!"


/datum/game_mode/nuclear/pre_setup()
	agents_possible = (get_player_count())/3
	if(agents_possible < 1)
		agents_possible = 1
	if(agents_possible > 5)
		agents_possible = 5

	var/list/possible_syndicates = list()
	possible_syndicates = get_possible_syndicates()
	var/agent_number = 0

	if(!possible_syndicates)
		return 0

	if(possible_syndicates.len < 1)
		return 0

	if(possible_syndicates.len > agents_possible)
		agent_number = agents_possible
	else
		agent_number = possible_syndicates.len

	while(agent_number > 0)
		var/datum/mind/new_syndicate = pick(possible_syndicates)
		syndicates += new_syndicate
		possible_syndicates -= new_syndicate //So it doesn't pick the same guy each time.
		agent_number--

	for(var/datum/mind/synd_mind in syndicates)
		synd_mind.assigned_role = "MODE" //So they aren't chosen for other jobs.

	uplink_uses = (syndicates.len*10)

	return 1


/datum/game_mode/nuclear/post_setup()
	for(var/obj/effect/landmark/synd_spawn/S in world)
		synd_spawns += S.loc
		del(S)

	for(var/obj/effect/landmark/disk_spawn/D in world)
		disk_spawns += D.loc
		del(D)

	var/obj/effect/landmark/nuke_spawn = locate("landmark*Nuclear-Bomb")
	var/obj/effect/landmark/closet_spawn = locate("landmark*Nuclear-Closet")

	var/nuke_code = "[rand(10000, 99999)]"
	var/leader_title = pick("Czar", "Boss", "Commander", "Chief", "Kingpin", "Director", "Overlord")
	var/leader_selected = 0

	for(var/datum/mind/synd_mind in syndicates)
		synd_mind.current.loc = pick(synd_spawns)
		synd_spawns -= synd_mind.current.loc

		var/datum/objective/nuclear/syndobj = new
		syndobj.owner = synd_mind
		synd_mind.objectives += syndobj

		var/obj_count = 1
		synd_mind.current << "\blue You are a [syndicate_name()] agent!"
		for(var/datum/objective/objective in synd_mind.objectives)
			synd_mind.current << "<B>Objective #[obj_count]</B>: [objective.explanation_text]"
			obj_count++

		if(!leader_selected)
			synd_mind.current.real_name = "[syndicate_name()] [leader_title]"
			synd_mind.store_memory("<B>Syndicate Nuclear Bomb Code</B>: [nuke_code]", 0, 0)
			synd_mind.current << "The nuclear authorization code is: <B>[nuke_code]</B>\]"
			synd_mind.current << "Nuclear Explosives 101:\n\tHello and thank you for choosing the Syndicate for your nuclear information needs.\nToday's crash course will deal with the operation of a Fusion Class NanoTrasen made Nuclear Device.\nFirst and foremost, DO NOT TOUCH ANYTHING UNTIL THE BOMB IS IN PLACE.\nPressing any button on the compacted bomb will cause it to extend and bolt itself into place.\nIf this is done to unbolt it one must compeltely log in which at this time may not be possible.\nTo make the device functional:\n1. Place bomb in designated detonation zone\n2. Extend and anchor bomb (attack with hand).\n3. Insert Nuclear Auth. Disk into slot.\n4. Type numeric code into keypad ([nuke_code]).\n\tNote: If you make a mistake press R to reset the device.\n5. Press the E button to log onto the device\nYou now have activated the device. To deactivate the buttons at anytime for example when\nyou've already prepped the bomb for detonation remove the auth disk OR press the R ont he keypad.\nNow the bomb CAN ONLY be detonated using the timer. A manual det. is not an option.\n\tNote: NanoTrasen is a pain in the neck.\nToggle off the SAFETY.\n\tNote: You wouldn't believe how many Syndicate Operatives with doctorates have forgotten this step\nSo use the - - and + + to set a det time between 5 seconds and 10 minutes.\nThen press the timer toggle button to start the countdown.\nNow remove the auth. disk so that the buttons deactivate.\n\tNote: THE BOMB IS STILL SET AND WILL DETONATE\nNow before you remove the disk if you need to move the bomb you can:\nToggle off the anchor, move it, and re-anchor.\n\nGood luck. Remember the order:\nDisk, Code, Safety, Timer, Disk, RUN\nGood luck."
			leader_selected = 1
		synd_mind.current << "\blue Use \":t\" to speak through encrypted Syndicate radio chanel."

		equip_syndicate(synd_mind.current)

	var/tmp/diskturf = pick(disk_spawns)
	new /obj/item/weapon/disk/nuclear(diskturf)

	if(nuke_spawn)
		var/obj/machinery/nuclearbomb/the_bomb = new /obj/machinery/nuclearbomb(nuke_spawn.loc)
		the_bomb.r_code = nuke_code

	if(closet_spawn)
		new /obj/structure/closet/syndicate/nuclear(closet_spawn.loc)

	for (var/obj/effect/landmark/A in world)
		if (A.name == "Syndicate-Gear-Closet")
			new /obj/structure/closet/syndicate/personal(A.loc)
			del(A)
			continue

		if (A.name == "Syndicate-Bomb")
			new /obj/item/weapon/syndie/c4explosive(A.loc)
			del(A)
			continue

		if (A.name == "Syndicate-Bomb-Strong")
			new /obj/item/weapon/syndie/c4explosive/heavy(A.loc)
			del(A)
			continue

	spawn (rand(waittime_l, waittime_h)*tick_multiplier)
		send_intercept()

	return

/datum/game_mode/nuclear/check_win()
	if (src.nuke_detonated)
		finished = 1
		return

	for(var/obj/item/weapon/disk/nuclear/D in world)
		var/disk_area = get_area(D)
		if(istype(disk_area, /area/shuttle/escape/centcom))
			finished = 2
			break

	return

/datum/game_mode/nuclear/check_finished()
	if((src.finished) || (main_shuttle.location==2))
		return 1
	else
		return 0

/datum/game_mode/nuclear/declare_completion()
	for(var/obj/item/weapon/disk/nuclear/D in world)
		var/disk_area = get_area(D)
		if(istype(disk_area, /area/shuttle/escape/centcom))
			finished = 2
			break

	switch(finished)
		if(0)
			world << "<FONT size = 3><B>Neutral Victory</B></FONT>"
			world << "<B>[syndicate_name()] operatives recovered the abandoned authentication disk but detonation of [station_name()] was averted.</B> Next time, don't lose the disk!"

		if(1)
			world << "<B>[syndicate_name()] operatives have destroyed [station_name()]!</B>"
			for(var/datum/mind/M in syndicates)
				if(!M.current)
					continue
				if(M.current.client)
					world << text("<B>[M.current.key] was [M.current.real_name]</B> [M.current.stat == 2 ? "(DEAD)" : ""]")

		if(2)
			world << "<FONT size = 3><B>The Research Staff has stopped the [syndicate_name()] Operatives!</B></FONT>"
			for(var/datum/mind/M in ticker.minds)
				if (!M.current)
					continue
				if ((M.current.client) && !(locate(M) in syndicates))
					world << text("<B>[M.current.key] was [M.current.real_name]</B> [M.current.stat == 2 ? "(DEAD)" : ""]")
	check_round()
	return 1



/obj/effect/landmark/synd_spawn
	name = "Syndicate-Spawn"
/obj/effect/landmark/nuke_spawn
	name = "Nuclear-Bomb"
/obj/effect/landmark/closet_spawn
	name = "Nuclear-Closet"
/obj/effect/landmark/gearcloset
	name = "Syndicate-Gear-Closet"
/obj/effect/landmark/synbomb
	name = "Syndicate-Bomb"
/obj/effect/landmark/synbomb/strong
	name = "Syndicate-Bomb-Strong"
/obj/effect/landmark/disk_spawn
	name = "Nuclear-Disk-Spawn"