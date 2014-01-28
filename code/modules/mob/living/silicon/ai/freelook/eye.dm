// AI EYE
// An invisible (no icon) mob that the AI controls to look around the station with.
// It streams chunks as it moves around, which will show it what the AI can and cannot see.
/mob/camera
	name = "camera mob"
	density = 0
	status_flags = GODMODE  // You can't damage it.
	mouse_opacity = 0
	see_in_dark = 7
	invisibility = 101 // No one can see us

/mob/camera/Move()
	return 0

// Hide popout menu verbs
/mob/camera/examine()
	set popup_menu = 0
	set src = usr.contents
	return 0

/mob/camera/pull()
	set popup_menu = 0
	set src = usr.contents
	return 0

/mob/camera/point()
	set popup_menu = 0
	set src = usr.contents
	return 0

/mob/camera/aiEye
	name = "Inactive AI Eye"

	var/list/visibleCameraChunks = list()
	var/mob/living/silicon/ai/ai = null


// Use this when setting the aiEye's location.
// It will also stream the chunk that the new loc is in.
/mob/camera/aiEye/proc/setLoc(var/T)
	if(ai)
		if(!isturf(ai.loc))
			return
		T = get_turf(T)
		loc = T
		cameranet.visibility(src)
		if(ai.client)
			ai.client.eye = src
		//Holopad
		//if(istype(ai.current, /obj/machinery/hologram/holopad))
		//	var/obj/machinery/hologram/holopad/H = ai.current
		//	H.move_hologram()

/mob/camera/aiEye/Move()
	return 0


// AI MOVEMENT
// The AI's "eye". Described on the top of the page.
/mob/living/silicon/ai
	var/mob/camera/aiEye/eyeobj = new()
	var/sprint = 10
	var/cooldown = 0
	var/acceleration = 0


// Intiliaze the eye by assigning it's "ai" variable to us. Then set it's loc to us.
/mob/living/silicon/ai/New()
	..()
	eyeobj.ai = src
	eyeobj.name = "[src.name] (AI Eye)" // Give it a name
	spawn(5)
		eyeobj.loc = src.loc
		if(client)
			client.eye = src

/mob/living/silicon/ai/Del()
	eyeobj.ai = null
	del(eyeobj) // No AI, no Eye
	..()

/atom/proc/move_camera_by_click()
	if(istype(usr, /mob/living/silicon/ai))
		var/mob/living/silicon/ai/AI = usr
		if(AI.eyeobj && AI.client.eye == AI.eyeobj)
			AI.cameraFollow = null
			AI.eyeobj.setLoc(src)

/mob/living/Click()
	if(isAI(usr))
		return
	..()

/mob/living/DblClick()
	if(isAI(usr) && usr != src)
		var/mob/living/silicon/ai/A = usr
		A.ai_actual_track(src)
		return
	..()

// This will move the AIEye. It will also cause lights near the eye to light up, if toggled.
// This is handled in the proc below this one.
/client/proc/AIMove(n, direct, var/mob/living/silicon/ai/user)
	var/initial = initial(user.sprint)
	var/max_sprint = 50

	if(user.cooldown && user.cooldown < world.timeofday) // 3 seconds
		user.sprint = initial

	for(var/i = 0; i < max(user.sprint, initial); i += 20)
		var/turf/step = get_turf(get_step(user.eyeobj, direct))
		if(step)
			user.eyeobj.setLoc(step)

	user.cooldown = world.timeofday + 5
	if(user.acceleration)
		user.sprint = min(user.sprint + 0.5, max_sprint)
	else
		user.sprint = initial

	user.cameraFollow = null

	//user.unset_machine() //Uncomment this if it causes problems.
	//user.lightNearbyCamera()

/client/proc/AIMoveZ(direct, var/mob/living/silicon/ai/user)
	if(direct == UP)
		direct = DOWN
	else
		direct = UP

	var/turf/step = get_step(user.eyeobj, direct)

	if(istype(step) && step.z <= 4 && step.z >= 1)
		user.eyeobj.setLoc(step)
	else
		user << "Subnetwork bounds reached. <A HREF=?src=\ref[user];switchsubnet=1>Switch subnetwork?</A>"

// Return to the Core.
/mob/living/silicon/ai/verb/core()
	set category = "AI Commands"
	set name = "AI Core"

	view_core()


/mob/living/silicon/ai/proc/view_core()
	cameraFollow = null
	unset_machine()

	if(src.eyeobj && src.loc)
		src.eyeobj.loc = src.loc
	else
		src << "ERROR: Eyeobj not found. Creating new eye..."
		src.eyeobj = new(src.loc)
		src.eyeobj.ai = src
		src.eyeobj.name = "[src.name] (AI Eye)" // Give it a name

	if(client && client.eye)
		client.eye = src
	for(var/datum/camerachunk/c in eyeobj.visibleCameraChunks)
		c.remove(eyeobj)

/mob/living/silicon/ai/verb/toggle_acceleration()
	set category = "AI Commands"
	set name = "Toggle Camera Acceleration"

	acceleration = !acceleration
	usr << "Camera acceleration has been toggled [acceleration ? "on" : "off"]."