var/list/occupations = list(
	"Engineer", "Engineer", "Engineer", "Engineer", "Engineer",
	"Security Officer", "Security Officer", "Security Officer", "Security Officer", "Security Officer",
	"Forensic Technician",
	"Geneticist", "Geneticist",
	"Scientist", "Scientist", "Scientist",  "Scientist",
	"Atmospheric Technician", "Atmospheric Technician",
	"Medical Doctor", "Medical Doctor", "Medical Doctor",
	"Head of Personnel",
	"Head of Security",
	"Chief Engineer",
	"Research Director",
	"Counselor",
	"Roboticist", "Roboticist",
	"Hydroponicist", "Hydroponicist",
	"AI",
	"Barman",
	"Chef",
	"Janitor", "Janitor",
	"Chemist", "Chemist",
	"Warden",
	"Clown",
	"Mime",
	"Quartermaster",
	"Shaft Miner","Shaft Miner",
	"Cargo Technician","Cargo Technician")

var/list/assistant_occupations = list("Unassigned")

/proc/IsResearcher(var/job)
	switch(job)
		if("Genticist")
			return 1
		if("Scientist")
			return 1
		if("Medical Doctor")
			return 1
		if("Roboticist")
			return 1
		if("Hydroponicist")
			return 1
		if("Research Director")
			return 2
		else
			return 0

/proc/GetRank(var/job)
	switch(job)
		if("Engineer")
			return 1
		if("Security Officer")
			return 2
		if("Forensic Technician")
			return 2
		if("Geneticist")
			return 1
		if("Scientist")
			return 1
		if("Atmospheric Technician")
			return 1
		if("Medical Doctor")
			return 1
		if("Head of Personnel")
			return 4
		if("Head of Security")
			return 3
		if("Chief Engineer")
			return 3
		if("Research Director")
			return 3
		if("Counselor")
			return 1
		if("Roboticist")
			return 1
		if("Hydroponicist")
			return 1
		if("Chemist")
			return 2
		if("Quartermaster")
			return 2
		if("Cargo Technician")
			return 0
		if("Shaft Miner")
			return 1
		if("Captain")
			return 5
		else
			return 0
			//world << "[job] NOT GIVEN RANK, REPORT JOB.DM ERROR TO CODER"

/proc/IsSecurity(var/job)
	if("Security Officer")
		return 1
	if("Forensic Technician")
		return 1
	if("Warden")
		return 1
	if("Head of Security")
		return 2
	else
		return 0