questions = []
count = 0
current_category = 'Science'
current_difficulty = 'hs_regs'

query_cat =  'Science'
query_diff = 'hs_regs'

current_queue = []

http = require 'http'
request = require 'request'

console.log 'loading local questions'
	
listProps = (prop) ->
	propmap = {}
	for q in questions
		propmap[q[prop]] = 1
	return (p for p of propmap)

filterQuestions = (diff, cat) ->
	console.log "filter called" + diff + cat
	if cat != ''
		query_cat = cat
	questions.filter (q) ->
		return false if diff and q.difficulty != diff
		return false if cat and q.category != cat
		return true

fisher_yates = (i) ->
	return [] if i is 0
	arr = [0...i]
	while --igoo
		j = Math.floor(Math.random() * (i+1))
		[arr[i], arr[j]] = [arr[j], arr[i]] 
	arr


initialize_remote = (cb) -> 
	fs = require 'fs'
	https = require 'https'
	https.request {
		hostname: 'googledrive.com',
		port: 443,
		path: '/host/0ByNPLvkdItdITjhJN1Q1aThoTFE/sample.txt',
		method: 'GET',
		rejectUnauthorized: false
	}, (res) ->
		data = ''
		res.on 'data', (chunk) -> data += chunk
		res.on 'end', ->
			questions = (JSON.parse(line) for line in data.split("\n") when line)
			console.log "parsed #{questions.length} questions"
			cb() if cb


handle_report = (data) -> console.log data

get_types = -> ['qb']

count_questions = (type, diff, cat, cb) -> cb filterQuestions(diff, cat).length

get_categories = (type) -> listProps('category')

get_difficulties = (type) -> listProps('difficulty')

get_parameters = (type, difficulty, cb) ->
	if difficulty != ''
		query_diff = difficulty
	cb get_difficulties(), get_categories()

get_by_id = (id, cb) -> cb null

get_question = (type, diff, cat, cb) ->
	if query_diff == ''
		query_diff = 'hs_regs'
	console.log query_cat + " & " + query_diff
	http = require 'http'
	http.get { host: 'qsrv.luminoso.dev',  path:"/q/"+query_diff+"/"+query_cat }, (res) ->
		data = ''
		res.on 'data', (chunk) ->
			data += chunk.toString()
		res.on 'end', () ->
			console.log data
			q = JSON.parse(data)
			cb q, get_difficulties(type), get_categories(type)
	# http.get { host: "qsrv.luminoso.dev", path:"/q/"+query_diff+"/"+query_cat }, (res) ->
	# 	console.log + "we did a thing!" + res
	# promise = $.getJSON "https://qsrv.luminoso.dev/q/"+diff+"/"+cat
	# promise.done (data) ->
	# 	console.log data
	# 	console.log "sending along!"
	#cb null, get_difficulties(type), get_categories(type)

exports.get_by_id = get_by_id
exports.get_question = get_question
exports.count_questions = count_questions
exports.get_categories = get_categories
exports.get_difficulties = get_difficulties
exports.get_parameters = get_parameters
exports.get_types = get_types
exports.initialize_remote = initialize_remote
exports.handle_report = handle_report
# exports.Report = Report
# exports.Question = question

exports.ready = (fn) -> fn()


generate_hmac = (cookie_base) -> 
	cookie_secret = "change me"
	sha1(cookie_secret + sha1(sha1(cookie_base) + sha1(cookie_secret)))

exports.secure_cookie = (data) ->
	cookie_base = encodeURIComponent(JSON.stringify(data))
	return generate_hmac(cookie_base) + "&" + cookie_base

exports.parse_cookie = (string) ->
	try
		[pseudo_hmac, cookie_base] = string.split("&")
		if generate_hmac(cookie_base) is pseudo_hmac
			return JSON.parse(decodeURIComponent(cookie_base))
	return null