
extends Control

var format
var news

var population = {
			'current': 0,
			'max': 10,
			'rate': 0.01
			}
var workforce = {
			'current': 0,
			'max': 0
			}
			
var workers = {
		0: 0,
		1: 0,
		2: 0,
		3: 0,
		}

var worker_panels
var pop_panel

func _ready():
	format = get_node('/root/formats')
	news = get_node('/root/Game/news')
	worker_panels = [
		get_node('Metal'),
		get_node('Crystal'),
		get_node('Nanium'),
		get_node('Tech')]
	pop_panel = get_node('home')
	_set_max_workforce()
	refresh()

func set_max_pop(n):
	var old_pop = population['max']
	population['max'] = n+10
	var diff = population['max'] - old_pop
	news.message(str(diff)+" spaces have just opened up for new Bots!")
	refresh()

func process(delta):
	var rate = 0.0
	if 2 <= int(population['current']):
		rate = population['current'] * population['rate']
	var new_pop = population['current'] + (rate * delta)
	if new_pop >= int(population['current']):
		_set_max_workforce()
		refresh()
	population['current'] = clamp(new_pop, 0, population['max'])
	
func refresh():
	if int(population['current']) >= population['max']:
		get_node('home/build').set_disabled(true)
	else:
		if get_node('home/build').is_disabled():
			get_node('home/build').set_disabled(false)
	
	for i in range(4):
		if workers[i] <= 0:
			workers[i] = 0
			worker_panels[i].get_node('decrease').set_disabled(true)
		else:
			if worker_panels[i].get_node('decrease').is_disabled():
				worker_panels[i].get_node('decrease').set_disabled(false)
		if is_workforce_full():
			worker_panels[i].get_node('increase').set_disabled(true)
		else:
			if worker_panels[i].get_node('increase').is_disabled():
				worker_panels[i].get_node('increase').set_disabled(false)
		worker_panels[i].get_node('amt').set_text(str(workers[i]))
	pop_panel.get_node('pop').set_text(str(int(population['current']),"/",population['max']))
	pop_panel.get_node('labor').set_text(str(workforce['current'],"/",workforce['max']))
	var pop_per = int((population['current']*1.0/population['max']*1.0)*100)
	if pop_panel.get_node('fillbar').get_value() != pop_per:
		pop_panel.get_node('fillbar').set_value(pop_per)
	
	for i in range(4):
		get_node('/root/Game/Bank').bank[i]['producers']['workers'] = workers[i]

func _set_max_workforce():
	var old_force = workforce['max']
	workforce['max'] = min(int(population['max']/2), int(population['current']))
	var diff = workforce['max'] - old_force
	if diff > 0:
		news.message(str(diff)+" new jobs have opened up. Get to work!")
func _change_current_population(n):
	population['current'] += n
	_set_max_workforce()


func _set_current_workforce():
	var total = workers[0]+workers[1]+workers[2]+workers[3]
	workforce['current'] = total	#current workforce cannot exceed current population

func is_workforce_full():
	if workforce['current'] == workforce['max'] or workforce['current'] == int(population['current']):
		return true
	return false
	

func _on_decrease_pressed(index):
	workers[index] -= 1
	_set_current_workforce()
	refresh()


func _on_increase_pressed(index):
	workers[index] += 1
	_set_current_workforce()
	refresh()


func _on_build_pressed():
	population['current'] += 1
	_set_max_workforce()
	refresh()
