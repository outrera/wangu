
extends Control

onready var game = get_node('/root/Game')
var current_event = 0
var event_object = {-1: null}

var DONE = false	#flag for disabling story when end of story is reached



#	EVENT SENSORS
var events = [
	{	#0
		'condition':	null,
		'message':	"""
You awake from your cryo-pod and climb out of the impact crater. The landscape 
around you is littered with scrap metal. Maybe you can do something useful with it.
"""
	},
	{	#1
		'condition':	['bank', 0, 15],	#bank 25 metal
		'message':	"""
A large building is discovered! It appears to be an old automated scrapyard.
You should be able to stash your gathered Metal here.
"""
	},
	{	#2
		'condition':	['skill',0,1],
		'message':	"""
You've gotten pretty good at gathering Metal! How 'bout you try harvesting some 
of the large crystal structures you see growing out of the dirt. The Crystal here
seems to show interesting energy-conduction properties.
"""
	},
	{	#3
		'condition':	['bank',1,20],
		'message':	"""
What is this?! You come across an abandoned Bot auto-factory. If you can build a
couple of these guys, they could help you gather resources.
"""
	},
	{	#4
		'condition':	['population', 3],
		'message':	"""
The Bots seem to be capable of self-replication! Now you know how robot babies are
made. You cannot bear to watch...yet you dare not look away!
"""
	},
	{	#5
		'condition':	['population', 5],
		'message':	"""
Things are getting crowded around here! You can start building [b]Shacks[/b] to house Bots
in.
"""
	},
	{	#6
		'condition':	['skill',1,1],
		'message':	"""
A curious Bot grabs your space-sleeve and drags you to a hidden location. It looks like this
little fella has discovered a vast network of caves! For some reason, this looks like the perfect
space to store all this awesome Crystal you have been harvesting. For some reason..
"""
	},
	{	#7
		'condition':	['population', 10],
		'message':	"""
Your Bots are starting to feel cramped in their crummy little Shacks. You consider designing
more spacious living arrangements, well before you start wondering why your Bots are feeling
anything at all...
"""
	},
	{
		'condition':	['population', 15],
		'message':	"""
[b][color=red]WARNING!! WARNING!![/color][/b] Hostile lifeforms detected in the area! Executing 
contingency program 1x0a4: \n All automated systems in IFF range SET to Militarized_Mode ON! 
"""
	},
	{
		'condition':	['kills', 3],
		'message':	"""
Your Troopers bring word from the battlefield! A rich vein of mysterious Nanium has been found
after their last tangle with the local wildlife. You roll up your sleeves begin the laborous
task of giving out orders.
"""
	},
	{
		'condition':	['miniboss_kills', 1],
		'message':	"""
Whoa! That was a mighty beast! You had better start researching some higher technology to begin
dealing with future challenges. For Science!!
"""
	},
	{
		'condition':	['bank',3,10],
		'message':	"""
Preliminary research has uncovered some cool new toys for your Troopers to play with!
"""
	},
	{
		'condition':	['total_kills',13],
		'message':	"""
Your one-bot army is impressive indeed! Not as impressive as a two-bot army, however...
"""
	},
	{
		'condition':	['population',30],
		'message':	"""
It's getting crowded again in your little robot city. You know what that means!
"""
	},
	{
		'condition':	['bank',3,50],
		'message':	"""
With a little know-how, you should be able to boost the production rates of your automated workers.
"""
	},
]




#	RESET/SAVE/RESTORE
func reset():
	pass
	
func save():
	var saveDict = {
	'current_event':	current_event
	}
	return saveDict

func restore(data):
	current_event = data['current_event']
	for i in range(current_event -1):
		_reward_event(i)
	game.update_storybar()

#	INIT
func _ready():
	pass

#	EVENT CONTROLLERS
func _set_event(E):
	event_object = events[E]

func _reward_event(E):
	var c = "_event_"+str(E)
	if has_method(c):
		call(c)

func _process_event(params):

	if params == null:
		return true
	
	elif params[0] == 'bank':		#require a number of a resource
		var material = params[1]
		var value  = params[2]
		if game.bank.can_afford(material,value):
			return true
	
	elif params[0] == 'kills':		#Requires total kills
		var value = params[1]
		if game.metrics.total_kills >= value:
			return true
	
	elif params[0] == 'miniboss_kills':		#require miniboss kills
		var value = params[1]
		if game.metrics.total_miniboss_kills >= value:
			return true
	
	elif params[0] == 'skill':		#require a level in resource skill
		var skill = params[1]
		var level = params[2]
		if game.bank.has_skill_level(skill,level):
			return true
	
	elif params[0] == 'population':
		var pop = params[1]
		if game.population.population['current'] >= pop:
			return true
	else:
		print("=====	NO PARAMETER EXISTS FOR CURRENT EVENT CONDITION!!!	=====")
	return false


func check_event():
	if DONE == false:
		if current_event < events.size():
			_set_event(current_event)
			var passed = _process_event(event_object['condition'])
			if passed:
				game.news.message(event_object['message'],game.game_time)
				_reward_event(current_event)
				current_event += 1
				game.update_storybar()
		else:
			DONE = true
			game.news.message("[b]End of Story Line.[/b]")



#	EVENT ACTUATORS

func _event_0():	#show Metal
	game.bank.get_node('Metal').show()
	game.bank.get_node('skills/Metal').show()
	game.news.message("You are now able to Salvage [b]Metal[/b]!")

func _event_1():	#add scrapyard
	game.construction.show()
	game.construction.make_scrapyard()
	game.construction.get_node('Buildings/cont').set_current_tab(1)


func _event_2():	#show Crystal
	game.bank.get_node('Crystal').show()
	game.bank.get_node('skills/Crystal').show()
	game.news.message("You are now able to Salvage [b]Crystal[/b]!")


func _event_3():	#show Metal workers
	game.population.show()
	game.population.get_node('Metal').show()
	game.news.message("You are now able to assign worker Bots to salvage [b]Metal[/b] for you!")

func _event_4():	#show Cyrstal workers
	game.population.get_node('Crystal').show()
	game.news.message("You are now able to assign worker Bots to salvage [b]Crystal[/b] for you!")

func _event_5():	#add shack
	game.construction.make_shack()
	game.construction.get_node('Buildings/cont').set_current_tab(0)
	game.news.message("Upgrading the [b]Shack[/b] will increase your maximum population!")

func _event_6():	#add crystalcaves
	game.construction.make_crystalcaves()
	game.construction.get_node('Buildings/cont').set_current_tab(1)
	game.news.message("Now you can store [b]Crystal[/b] as well as Metal!")

func _event_7():	#add garage
	game.construction.make_garage()
	game.construction.get_node('Buildings/cont').set_current_tab(0)
	game.news.message("The [b]Garage[/b] will allow you to expand your Bot population even farther!")

func _event_8():	#show combat map
	game.combat.show()
	game.construction.make_claws()
	game.construction.make_hardplate()
	game.construction.get_node('Buildings/cont').set_current_tab(3)
	game.news.message("Click the [b]Fight[/b] button to make your Bot fight monsters!")

func _event_9():	#show Nanium workers
	game.bank.get_node('Nanium').show()
	game.bank.get_node('skills/Nanium').show()
	game.population.get_node('Nanium').show()
	game.construction.make_naniteservers()
	game.news.message("You are now able to assign worker Bots to synthesize [b]Nanium[/b] for you!")

func _event_10():	#show research
	game.bank.get_node('Tech').show()
	game.bank.get_node('skills/Tech').show()
	game.news.message("You are now able to assign worker Bots to research [b]Tech[/b] for you!")

func _event_11():	#show Shields & Lasers
	game.construction.make_shields()
	game.construction.make_lasers()
	game.news.message("New Equipment discovered!  [b]Shields[/b] will soak up incoming damage. [b]Lasers[/b] will give your army much more punch.")
	
func _event_12():	#show Battle Tactics
	game.construction.make_battletactics()
	game.population.get_node('Tech').show()
	game.combat.show_autofight()
	game.news.message("Research [b]Battle Tactics[/b] to increase the amount of Troopers in your army. Today, Alpha Sector. Tomorrow..the world!!")

func _event_13():	#Show Hangar
	game.construction.make_hangar()
	game.news.message("Hangars will really let you expand your population.")

func _event_14():	#Show Boost researches
	game.construction.make_metallurgy()
	game.construction.make_attunement()
	game.construction.make_synthesis()
	game.news.message("Research will allow you to increase your production in that particular resource. Defeat Mini-Bosses to unlock new Research upgrades!")
