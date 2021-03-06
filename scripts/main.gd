
extends Node

var format

var story
var metrics

var bank
var population
var combat
var news
var construction

var time_label
var game_time = 0.0
onready var story_bar = get_node('storybar')

var autoload = true

var autosave = true
var autosave_timer = 0.0	#timer in sec
var autosave_interval = 5	#in minutes

var is_menu_open = false

func _ready():
	ready_settings()
	format = get_node('/root/formats')
	#master links
	story = get_node('Story')
	metrics = get_node('Metrics')
	
	bank = get_node('Bank')
	population = get_node('population')
	combat= get_node('combat')
	news = get_node('news')
	construction = get_node('construction')
	time_label = get_node('sys_panel/time')
	
	story_bar.set_max(story.events.size())
	
	set_process(true)
	
	if autoload == true:
		load_game()
	else:
		new_game()

func ready_settings():
	var saveGame = File.new()
	if saveGame.file_exists('res://saves/savegame.sav'):
		var loadNodes = {}
		#Open file to Read
		saveGame.open('res://saves/savegame.sav', File.READ)
		#Go through file lines and append each line to loadNodes
		while (!saveGame.eof_reached()):
			loadNodes.parse_json(saveGame.get_line())
		if 'settings' in loadNodes:
			var set = loadNodes['settings']
			autoload = set['autoload']

#	HEARTBEAT	#
func _process(delta):
	
	#GAME CLOCK
	game_time += delta
	var t = format.time(game_time)
	time_label.set_text(str("Time: ",t))
	
	#AUTOSAVE
	if autosave:
		autosave_timer += delta
		if autosave_timer >= (autosave_interval*60):	#convert minutes > seconds
			autosave_timer = 0.0
			save_game()
			news.message("auto-saving...",game_time)
	
			#STORY EVENT PROCESS#
	story.check_event()
			#MODULE PROCESSES
	#BANK
	bank.process(delta)
	#POPULATION
	population.process(delta)
	#COMBAT
	combat.process(delta)
	#NEWS
	
	#CONSTRUCTION




#######################################
###		SAVE / RESTORE / NEW GAME	###
#######################################
func save_game(legacy=false):
	#Save the current game state
	var saveGame = File.new()
	#open file for writing (overwrites old file)
	if legacy:
		saveGame.open('user://savegame.sav', File.WRITE)
	else:
		saveGame.open("res://saves/savegame.sav", File.WRITE)
	#Get save data from all modules, put them into a GlobDick
	var saveNodes = {
		'time':			game_time,
		'settings':	{
			'autosave':	autosave,
			'autosave_interval':	autosave_interval,
			'autoload':		autoload,
			'fullscreen':	get_node('sys_panel').fullscreen
				},
			'story':	story.save(),
			'metrics':	metrics.save(),
		'bank':			bank.save(),
		'population':	population.save(),
		'construction': construction.save(),
		'combat':		combat.save()
		}
	#Write to file and close it
	saveGame.store_line(saveNodes.to_json())
	news.message("[b]Game Saved![/b]",game_time)
	saveGame.close()


func load_game():
	#Load the currently-saved game state
	#Only one save slot for now.
	var saveGame = File.new()
	
	#Legacy: Check for old savegame.sav in user://
	if saveGame.file_exists('user://savegame.sav'):
		save_game(true)
		print("Old savegame.sav found!  Converting..")
		if saveGame.file_exists('res://saves/savegame.sav'):
			var usr = Directory.new()
			var dir = usr.open('user://')
			if dir == 0:
				var file = usr.remove('user://savegame.sav')	###???
				if file != 0:
					print("OLD SAVE NOT PURGED!")
					print(file)
				else:
					print("old save successfully purged")

	#Make sure our file exists:
	if not saveGame.file_exists('res://saves/savegame.sav'):
		print("no savegame found!")
		return
	#Dict to hold json lines
	var loadNodes = {}
	#Open file to Read
	saveGame.open('res://saves/savegame.sav', File.READ)
	#Go through file lines and append each line to loadNodes
	while (!saveGame.eof_reached()):
		loadNodes.parse_json(saveGame.get_line())
	prints("LOADING DICTS: ",loadNodes.keys(),'\n')
	
	###	DONE GETTING DATA. NOW RESTORE THE GAME MODULES	###
	saveGame.close()
	
	#Restore global game time
	if 'time' in loadNodes:
		prints("Setting game Time:",format.verbose_time(loadNodes['time']))
		game_time = loadNodes['time']
	else:
		print("No game time saved! Setting to 0s")
		game_time = 0
	
	#Restore game settings
	if 'settings' in loadNodes:
		var set = loadNodes['settings']
		prints("Restoring Population:", set.keys() )
		
		autosave = set['autosave']
		autosave_interval = int(set['autosave_interval'])
		autoload = set['autoload']
		get_node('sys_panel').fullscreen = set['fullscreen']
		get_node('sys_panel')._set_screen_mode()
	else:
		print("No Game Settings found! No worries, they'll be made next time you save \n")
	
	#Restore Metrics
	if 'metrics' in loadNodes:
		metrics.restore(loadNodes['metrics'])

	
	#1.Restore Construction/Structures
	construction.restore(loadNodes['construction'])
	
	#2.Restore Population
	population.restore(loadNodes['population'])
	
	#3.Restore Bank
	bank.restore(loadNodes['bank'])
	
	#4.Restore Combat/Map
	combat.restore(loadNodes['combat'])

	#Restore Story events
	if 'story' in loadNodes:
		story.restore(loadNodes['story'])

	news.message("[b]Game Loaded![/b]",game_time)




func new_game():
	news.reset()
	construction.reset()
	population.reset()
	combat.reset()
	bank.reset()
	news.message("[b]GAME RESET![/b]")

	game_time = 0



func quit_game():
	get_tree().quit()

func update_storybar():
	story_bar.set_value(story.current_event)



#####################
#	CHILD SIGNALS	#
#####################

func _on_save_pressed():
	get_node('sys_panel/save').set_disabled(true)
	get_node('sys_panel/save/save_confirm').popup()

func _on_save_confirm_confirmed():
	save_game()

func _on_save_confirm_popup_hide():
	get_node('sys_panel/save').set_disabled(false)



func _on_load_pressed():
	load_game()


func _on_new_pressed():
	get_node('sys_panel/new').set_disabled(true)
	get_node('sys_panel/new/reset_confirm').popup()



func _on_reset_confirm_confirmed():
	new_game()

func _on_reset_confirm_popup_hide():
	get_node('sys_panel/new').set_disabled(false)



func _on_exit_pressed():
	save_game()
	quit_game()
	

func _on_exit1_pressed():	#Quit without saving
	quit_game()
