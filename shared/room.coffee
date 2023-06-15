# i really wanted to have it calculate the distribution of things dynamically and generate this
# but the problem is that I don't have a system which is based on absolute percentages, so the
# problem is that you can't quite change absolute percentages or something
# i mean, technically it's possible to do the computation and it'd be pretty cool to be
# able to do that, and actually it's fairly trivial, but it's more effort than I'm currently
# willing to exert


error_question = {
	'category': '$0x40000',
	'difficulty': 'segmentation fault',
	'num': 'NaN',
	'tournament': 'Guru Meditation Cup',
	'question': 'This type of event occurs when the queried database returns an invalid question and is frequently indicative of a set of constraints which yields a null set. Certain manifestations of this kind of event lead to significant monetary loss and often result in large public relations campaigns to recover from the damaged brand valuation. This type of event is most common with computer software and hardware, and one way to diagnose this type of event when it happens on the bootstrapping phase of a computer operating system is by looking for the POST information. Kernel varieties of this event which are unrecoverable are referred to as namesake panics in the BSD/Mach hybrid microkernel which powers Mac OS X. The infamous Disk Operating System variety of this type of event is known for its primary color backdrop and continues to plague many of the contemporary descendents of DOS with code names such as Whistler, Longhorn and Chidori. For 10 points, name this event which happened right now.',
	'answer': 'error',
	'year': 1970,
	'round': '0x080483ba'
}

error_bonus = {
	'category': 'Mission Accomplished',
	'difficulty': 'null',
	'num': 'undefined',
	'tournament': 'magic smoke',
	'question': 'This question has not yet been written.',
	'answer': 'failure',
	'year': 2003,
	'round': '1'	
}


# default_distribution = {"Fine Arts":2,"Literature":4,"History":3,"Science":3,"Trash":1,"Geography":1,"Mythology":1,"Philosophy":1,"Religion":1,"Social Science":1}


# Tyger! Tyger! burning bright 
# In the forests of the night, 
# What immortal hand or eye 
# Could frame thy fearful symmetry? 

class QuizRoom
	constructor: (name = "temporary") ->
		@name = name
		@type = "qb"
		@realm = null

		@answer_duration = 5 * 1000
		@attempt_duration = 8 * 1000
		@prompt_duration = 10 * 1000

		@time_offset = 0
		@sync_offset = 0 # always zero for master installations
		@start_offset = 0 # to compensate for latency, etc.
		
		@last_action = 0
		@time_spent = 0
		@seen = 0
		@end_time = 0
		@begin_time = 0
		
		@question = ''
		@value = null
		@answer = ''
		@info = {}

		@qid = null
		@timing = []
		@cumulative = []

		@rate = 1000 * 60 / 5 / 200
		@__timeout = {}
		@distribution = null

		@freeze()
		@users = {}
		
		@difficulty = ''
		@category = ''
		@max_buzz = null
		@attempt = null
		@no_skip = false
		@show_bonus = false
		# @interrupts = true
		@semi = false
		@no_pause = false
		@dystopia = 0
		
		@created = @serverTime()

		@scoring = {
			normal: [10, 0],
			early: [20, -5],
			interrupt: [10, -5]
		}

		@acl = {
			# pariah:    50,
			baseline:  100,
			positive:  110,
			fifty:     120,
			unlocked:  200,
			elected:   230,
			moderator: 300,
			admin:     310,
			ninja:     400
		}

		# the default level necessary to call authorized()

		@mute = @acl.baseline
		@escalate = @acl.unlocked


	touch: ->
		current_time = @serverTime() 
		elapsed = current_time - @last_action
		if elapsed < 1000 * 60 * 3
			@time_spent += elapsed
		@last_action = current_time

	log: (message) -> @emit 'log', { verb: message }

	# is this the only room.coffee function which gets called from
	# the client side? that's rather odd design wise
	# this is objective locking, not subjective locking
	locked: ->
		return true if @escalate and @escalate > @acl.unlocked

		lock_electorate = 0
		lock_votes = 0

		for id, user of @users when user.active()
			if user.active()
				lock_electorate++
				lock_votes++ if user.lock
		
		needed = Math.floor(lock_electorate / 2 + 1)
		
		if lock_electorate <= 2
			return false
		
		if lock_votes >= needed
			return true
		
		return false

	admin_online: ->
		for id, user of @users when user.active() and user.authorized 'moderator'
			return true
		return false


	active_count: ->
		active_count = 0
		active_count++ for id, user of @users when user.active()
		return active_count

	get_parameters: (type, difficulty, cb) -> # cb(difficulties, categories)
		console.log 'get_parameters was called. woo.'
		#  async version of get_difficulties and get_categories
		@emit 'log', {verb: 'NOT IMPLEMENTED (async get params)'}
		cb ['HS', 'MS'], ['Science', 'Trash']

	count_questions: (type, difficulty, category, cb) ->
		@log 'NOT IMPLEMENTED (question counting)'

	get_size: (cb, type = @type, difficulty = @difficulty, category = @category) ->
		@count_questions type, difficulty, (if category is 'custom' then @distribution else category), (count) ->
			cb count

	get_question: (cb) ->
		setTimeout =>
			if @next_id is '__error_bonus'
				cb error_bonus
			else
				cb error_question
		, 10
		@log 'NOT IMPLEMENTED (async get question)'

		
	# emit_user: (id, args...) ->
	# 	@log 'room.emit_user(id, name, data) not implemented'


	# note to self, do not change this into an @log, because thats recursive
	emit: (name, data) -> console.log 'room.emit(name, data) not implemented'

	reset_distribution: -> 
		big_dist = {}

		test_distribution = (factor) ->
			smaller = {}
			error = 0
			count = 0
			total = 0
			for cat, num of big_dist
				smaller[cat] = Math.round(num / factor)
				count += smaller[cat]
				total += num
				error += Math.abs(smaller[cat] * factor - num)
			

			return [smaller, error / total + count / 20]

		simplify_distribution = =>
			min = Infinity
			# calculate the smallest number of questions in a category
			# exclude the 1-element ones because they're probably bugs
			min = num for cat, num of big_dist when num < min and num > 1 

			# iteratively refine the factor
			guess = min
			[s_base, e_base, c_base] = test_distribution(guess)
			return s_base

			# [s1, e1, c1] = test_distribution(min - 1)
			# [s2, e2, c2] = test_distribution(min + 1)
			# guess = min
			# [s_base, e_base, c_base] = test_distribution(guess)
			# console.log e_base, e1, e2
			# if e_base < e1 and e_base < e2
			# 	console.log 'got smallest'
			# 	return s_base


		@get_parameters @type, @difficulty, (difficulties, categories) =>
			next_cat = =>
				cat = categories.shift()
				if cat
					@count_questions @type, @difficulty, cat, (count) =>
						big_dist[cat] = count
						next_cat()
				else
					@distribution = simplify_distribution()

			next_cat()
		# @distribution = default_distribution

	time: -> if @time_freeze then @time_freeze else @offsetTime()

	offsetTime: -> @serverTime() - @time_offset

	serverTime: -> new Date - @sync_offset

	set_time: (ts) -> @time_offset = @serverTime() - ts

	freeze: -> @time_freeze = @time()

	unfreeze: ->
		if @time_freeze
			@set_time @time_freeze
			@time_freeze = 0

	timeout: (delay, callback) ->
		@clear_timeout()
		@__timeout = setTimeout callback, delay

	clear_timeout: -> clearTimeout @__timeout

	check_timeout: ->
		if @attempt
			if @serverTime() > @attempt.realTime + @attempt.duration
				@clear_timeout()
				@end_buzz @attempt.session
		# if @no_pause and !@attempt and @time_freeze
		# 	@room.unfreeze()


	new_question: ->
		@generating_question = @serverTime()

		@get_question (question) =>
			if !question or !question.question or !question.answer
				question = error_question
				
			delete @generating_question;
			@generated_time = @serverTime() # like begin_time but doesnt change when speed is altered
			
			@attempt = null

			@clear_timeout()
			
			@next_id = question.next || null # might be null

			@info = {
				category: question.category, 
				difficulty: question.difficulty, 
				tournament: question.tournament, 
				num: question.num, 
				year: question.year, 
				date: question.date,
				group: question.group,
				tags: question.tags,
				round: question.round
			}
			
			@value = question.value || null
			
			@question = question.question
				.replace(/FTP/g, 'For 10 points')
				.replace(/^\[.*?\]/, '')
				.replace(/\n/g, ' ')
				.replace(/\s+/g, ' ')
			@answer = question.answer
				.replace(/\<\w\w\>/g, '')
				.replace(/\[\w\w\]/g, '')

			@qid = question?._id?.toString() || question?.qid || question?.id || 'question_id'
			
			@begin_time = @time() + @start_offset

			if SyllableCounter?
				syllables = SyllableCounter
			else
				syllables = require('./lib/syllable').syllables

			# in case syllables gives anything really weird (which has happened before)
			@timing = for word in @question.split(" ")
				syl = +syllables(word) || 0
				if word.split('.').length > 1
					if word.lenth > 2
						syl += 4
					else
						syl += 2
				if word.split(',').length > 1
					syl += 2
				1 + syl

			@set_speed @rate #do the math with speeds
			
			has_early = @question.indexOf('*') > 5

			# increment the number of questions this room has seen
			@seen++

			for id, user of @users
				# reset the number of times the user is allowed to buzz for this question
				user.times_buzzed = 0
				
				if user.active()
					user.seen++
					user.earlyseen++ if has_early

				user.history.push user.score()
				user.history = user.history.slice(-60)
			
			@journal()
			@sync(3)

	# So I think this vaguely deserves to be documented because its actually
	# a little weird. This thing lets you change the speed while the question 
	# is still being read out, and that means all the state and whatever 
	# variables need to be altered such that it works. In order to preserve
	# the read state when something's changed, it alters the beginning time
	# retroactively such that the read speed alters and the question readout
	# is at the same point.

	set_speed: (rate) ->
		return unless rate # prevent weird instances where you set_speed to null

		cumsum = (list, rate) ->
			sum = 0 #start nonzero, allow pause before rendering
			for num in [5].concat(list).slice(0, -1)
				sum += Math.round(num * rate) #always round!

		now = @time() # take a snapshot of time to do math with
		#first thing's first, recalculate the cumulative array
		@cumulative = cumsum @timing, @rate
		#calculate percentage of reading right now
		elapsed = now - @begin_time
		duration = @cumulative[@cumulative.length - 1]
		done = elapsed / duration

		# if it's past the actual reading time
		# this means altering the rate doesnt actually
		# affect the length of the answer_duration
		remainder = 0
		if done > 1
			remainder = elapsed - duration
			done = 1
		
		# set the new rate
		@rate = rate
		# recalculate the reading intervals
		@cumulative = cumsum @timing, @rate
		new_duration = @cumulative[@cumulative.length - 1]
		#how much time has elapsed in the new timescale
		@begin_time = Math.round(now - new_duration * done - remainder)
		# set the ending time
		@end_time = Math.round(@begin_time + new_duration + @answer_duration)

		# test
		@begin_time = 0 if isNaN(@begin_time)
		@end_time = 0 if isNaN(@end_time)


	finish: -> 
		@emit 'finish_question', @time()
		@set_time @end_time

	next: ->
		return if @attempt or @time() <= @end_time
		
		if @generating_question and @serverTime() - @generating_question > 2000
			delete @generating_question
			return

		return if @generating_question
		
		@unfreeze()
		@new_question()
			

	check_answer: (attempt, answer, question) ->
		# this is a mock answer checker in lieu of an actual one
		return 'prompt' if Math.random() > 0.8
		return Math.random() > 0.3

	end_buzz: (session) -> #killit, killitwithfire
		return unless @attempt?.session is session
		user = @users[@attempt?.user]

		# maybe the user just died...?
		if !@attempt or !user
			@attempt = null
			@sync()
			return

		# prompts are weird
		unless @attempt.prompt
			@clear_timeout()
			@attempt.done = true
			@attempt.correct = @check_answer @attempt.text, @answer, @question
			do_prompt = false
			
			if @attempt.correct is 'prompt'
				do_prompt = true
				@attempt.correct = false
			
			# conditionally set this based on stuff
			if do_prompt is true
				@attempt.correct = "prompt" # quasi hack i know

				@sync() # sync to create a new line in the annotats

				@attempt.prompt = true

				@attempt.done = false
				@attempt.realTime = @serverTime()
				@attempt.start = @time()
				@attempt.text = @attempt.text.trim() + ' '
				@attempt.duration = @prompt_duration

				@timeout @attempt.duration, => #@serverTime, @attempt.realTime + @billMahrer, =>
					@end_buzz session

				# increment the number of prompts the user has been given
				user.prompts++

			@sync()
		else
			@attempt.done = true
			@attempt.correct = @check_answer @attempt.text, @answer, @question
			@attempt.correct = false if @attempt.correct is 'prompt'
			@sync()

		if @attempt.done
			@unfreeze()
			
			value = @value
			if value is null
				value = 'normal'
				value = 'interrupt' if @attempt.interrupt
				value = 'early' if @attempt.early

			unless value of @scoring
				@log "Warning: entry `#{value}` does not exist in the scoring matrix and will not be counted. Please contact info@protobowl.com to resolve this issue."

			if @attempt.correct
				# woo increment mah streak
				user.streak++
				user.streak_record = Math.max(user.streak, user.streak_record)
				# end everyone else's streak
				for id, u of @users when id isnt @attempt.user
					u.streak = 0
				# end mah negstreak
				user.negstreak = 0
				# gimme mah points
				if ((typeof user.corrects[value]) != 'number') or isNaN(user.corrects[value])
					user.corrects[value] = 0 

				user.corrects[value]++
				@finish()
			else # incorrect
				user.streak = 0
				user.negstreak++
				user.negstreak_record = Math.max(user.negstreak, user.negstreak_record)

				if typeof user.wrongs[value] != 'number' or isNaN(user.wrongs[value])
					user.wrongs[value] = 0 
				user.wrongs[value]++
				

				buzzed = 0
				pool = 0
				teams = {}
				for id, u of @users when id[0] isnt "_" # skip secret ninja
					if u.active()
						teams[u.team || id] = (teams[u.team || id] || 0)
						teams[u.team || id] += u.times_buzzed
				for team, times_buzzed of teams
					if times_buzzed >= @max_buzz and @max_buzz
						buzzed++
					pool++
				if @max_buzz
					# console.log 'people buzzed', buzzed, 'of', pool
					if buzzed >= pool 
						@finish() # if everyone's buzzed and nobody can buzz, then why continue reading

			@journal()
			@attempt = null #g'bye
			@sync(2) #two syncs in one request!


	buzz: (user, fn) -> #todo, remove the callback and replace it with a sync listener
		team_buzzed = 0

		return false unless user of @users

		for id, member of @users when (member.team || id) is (@users[user].team || user)
            team_buzzed += member.times_buzzed
            
		if @max_buzz and @users[user].times_buzzed >= @max_buzz
			fn 'THE BUZZES ARE TOO DAMN HIGH' if fn
			if !@attempt
				@emit 'log', {user: user, verb: 'has already buzzed'}

		else if @max_buzz and team_buzzed >= @max_buzz
			fn 'THE BUZZES ARE TOO DAMN HIGH' if fn
			@emit 'log', {user: user, verb: 'is in a team which has already buzzed'}

		else if !@scoring?.interrupt and @time() <= @end_time - @answer_duration
			@emit 'log', {user: user, verb: 'attempted an illegal interrupt'}
			fn 'THE GAME' if fn

		else if !@attempt and @time() <= @end_time
			fn 'http://www.whosawesome.com/' if fn
			session = Math.random().toString(36).slice(2)
			early_index = @question.replace(/[^ \*]/g, '').indexOf('*')


			@attempt = {
				user: user,
				realTime: @serverTime(), # oh god so much time crap
				start: @time(),
				duration: @attempt_duration,
				session, # generate 'em server side 
				text: '',
				early: early_index != -1 and @time() < @begin_time + @cumulative[early_index],
				interrupt: @time() < @end_time - @answer_duration,
				done: false
			}

			@users[user].times_buzzed++
			# @users[user].guesses++
			
			@freeze()
			@sync(2) #partial sync
			@timeout @attempt.duration, => #@serverTime, @attempt.realTime + @attempt.duration, =>
				@end_buzz session

			return true

		else if @attempt
			@emit 'log', {user: user, verb: 'lost the buzzer race'}
			fn 'THE GAME' if fn
		else
			@emit 'log', {user: user, verb: 'attempted an invalid buzz'}
			fn 'THE GAME' if fn

		return false

	guess: (user, data) ->
		# @touch user
		if @attempt?.user is user
			@attempt.text = data.text.slice(0, 200)
			# lets just ignore the input session attribute
			# because that's more of a chat thing since with
			# buzzes, you always have room locking anyway
			if data.done
				# do done stuff
				# console.log 'omg finals clubs are so cool ~ zuck'
				@end_buzz @attempt.session
			else
				@sync(-1)

	# 'Living backwards!' Alice repeated in great astonishment. 'I never heard of such a thing!'
	# '--but there's one great advantage in it, that one's memory works both ways.'
	# 'I'm sure MINE only works one way,' Alice remarked. 'I can't remember things before they happen.'
	# 'It's a poor sort of memory that only works backwards,' the Queen remarked.

	sync: (level = 0) ->
		data = { real_time: @serverTime() }


		whitelist = ["time_offset", "time_freeze", "attempt"]
		# there is a very minimal sync level for the basic stuff
		data[attr] = this[attr] for attr in whitelist

		blacklist = ["cumulative", "users", "sync_offset", "generating_question"]
		level3 = ["question", "answer", "timing", "info", "generated_time"]
		level4 = ["realm", "created", "topic", "acl", "scoring"]

		user_blacklist = ["sockets", "room"]

		if level.id # that's no number! that's a user!
			user = {}
			for attr of level when attr not in user_blacklist and typeof level[attr] not in ['function'] and attr[0] != '_'
				user[attr] = level[attr]
			user.online_state = level.online()
			data.users = [user]
			return data

		if level >= 1
			# all the additional attributes that aren't done in level 0
			for attr of this when typeof this[attr] != 'function' and attr not in blacklist and attr not in level3 and attr not in level4 and attr[0] != "_"
				data[attr] = this[attr]

		if level >= 2
			# sync the user data, which is actually quite a bit of stuff
			data.users = for id of @users when id[0] isnt '_'
				user = {}
				for attr of @users[id] when attr not in user_blacklist and typeof @users[id][attr] not in ['function'] and attr[0] != '_'
					user[attr] = @users[id][attr] 
				user.online_state = @users[id].online()
				# console.log user
				user

		if level >= 3
			data[attr] = this[attr] for attr in level3

		if level >= 4
			data[attr] = this[attr] for attr in level4

			# in case no distribution has been generated
			@reset_distribution() unless @distribution

			# async stuff
			@get_parameters @type, @difficulty, (difficulties, categories) =>
				console.log 'get_parameteres 2'
				data.difficulties =  ["ms", "hs_easy", "hs_regs","hs_hard","hs_nats","college_easy","college_medium","college_regional","college_nats","open"]
				data.categories = ["Literature", "History", "Science", "Fine Arts", "Religion", "Mythology", "Philosophy", "Social Science", "Current Events", "Geography", "Other Academic", "Trash"]
				
				if @difficulty and @difficulty not in difficulties
					@difficulty = ''
				if @category and @category isnt 'custom'
					if @category not in categories
						@category = ''

				if @distribution
					for cat in categories
						@distribution[cat] = @distribution[cat] || 0
					for key of @distribution when key not in categories
						delete @distribution[key]
					data.distribution = @distribution

				@emit 'sync', data

			@journal()
		else
			if level < 0
				for id, user of @users when !user.muwave
					user.emit 'sync', data
			else
				@emit 'sync', data
	
	journal: -> 0 # unimplemented

	delete_user: (id) ->
		return false unless @users[id]
		if id[0] isnt '_'
			@emit 'delete_user', id
		@users[id] = null
		delete @users[id]

	serialize: ->
		data = {}
		blacklist = ['users', 'attempt', 'generating_question', 'acl', "_id", "_ip_ban"]
		for attr of this when attr not in blacklist and typeof this[attr] not in ['function'] and attr[1] != '_'
			data[attr] = this[attr]
		data.users = (user.serialize() for id, user of @users)
		return data


exports.QuizRoom = QuizRoom if exports?
