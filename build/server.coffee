#!/usr/bin/env /usr/local/bin/coffee

sys = require 'sys'
fs = require 'fs'
URL = require 'url'
http = require 'http'
qs = require 'querystring'
util = require 'util'
coffee = require 'coffee-script'
exec = require('child_process').exec

config = {}

trim = (str)->str.replace(/(^\s+|\s+$)/,'')

processData = (data, method, response) ->
	out = ""
	params = qs.parse data
	console.dir "processing req #{method}:"
	for key,val of params
		console.log "\t#{key}=#{val}"
	try 
		console.log "processing request for #{params.action}"
		switch method
			when 'POST'
				switch params.action
					when null
						out = "specify the action yo"
					when 'compile'
						out = coffee.compile params.content
					when 'fileList'
						list = {}
						fl = fs.readdirSync params.path
						for f in fl
							try
								stats = fs.statSync "#{params.path}/#{f}"
								if stats.isFile() and f.indexOf('.coffee')<1
									console.log "skipping #{f}"
									continue
								list[f] = if stats.isDirectory() then 'directory' else 'file'
							catch e
								console.err e
						out = list 
						console.log("got file list:#{out.toString()}")
					when 'log'
						console.log "LOG:#{params.message}"
						out = ""
					when 'getConfig'
						out = {config:config}
					when 'save'
						if params.fn is null
							out = "filename missing"
						else if params.content is null
							out = "no file content found!"
						else
							console.log "saving file #{params.fn}"
							fs.writeFileSync params.fn, params.content
							out = "save complete"
							
					when 'open'
						if params.fn is null
							out = "filename missing"
						else if params.content is null
							out = "no file content found!"
						else
							console.log "opening file #{params.fn}"
							content = fs.readFileSync params.fn, 'utf8'
							console.log "got content \n #{content}"
							out = {content:content}
							updateLastFilesConfig('add', params.fn)
							saveConfig()
					when 'close'
						if params.fn is null
							out = "filename missing"
						else
							updateLastFilesConfig 'del', params.fn
	catch e
		console.log e.stack
		out = e.message
	out = JSON.stringify out
	response.end out
	console.log "sending back #{out}"
	
loadConfig = ->
	fs.readFile ".brewer.conf", (err,data) ->
		try
			if err then throw err
			else
				config = JSON.parse(data)
				console.log "config loaded"
		catch e
			exec 'cd;pwd',(e,so,se)->
				config.home = trim(so)
				config.lastFiles = []
				console.log "home folder is #{config.home}"
				saveConfig()
		



saveConfig = ->
	fs.writeFile ".brewer.conf", JSON.stringify(config), (err) ->
		throw err if err
		console.log "config saved"
		
updateLastFilesConfig = (action, fn) ->
	console.log "updateLastFileConfig #{action} #{fn}"
	console.log "lastFiles before update:#{config.lastFiles}"
	try
		for i,f of config.lastFiles
			console.log "#{f} vs #{fn}"
			if f is fn
				if action is 'add'
					return
				else if action is 'del'
					config.lastFiles.splice i, 1
		if action is 'add'
			config.lastFiles.push fn
	finally
		console.log "lastFiles after update:#{config.lastFiles}"

############ MAIN ############

loadConfig()

	
http.createServer( (req, res) ->
	try
		# console.log req.url
		url = URL.parse(".#{req.url}").pathname
		console.log "url: #{url}"
		method = req.method
		console.log "method:#{method}"
	
		data = null
		req.addListener 'data',(d) ->
			data = d.toString()
			# console.log "data from #{method}:#{data}"
			
		req.addListener 'end', ->
			if data? and method isnt "GET" 
				console.log "data:#{data}"
				res.writeHead(200, {'Content-Type': 'application/json'});
				processData(data, method, res)
			else
				try
					res.writeHead(200, {'Content-Type': 'text/html'});
					stats = fs.statSync(url)
					# console.log stats
					if stats.isDirectory()
						# console.log 'isDir'
						url = url+'/index.html'
						url = url.replace '//', '/'
						res.end fs.readFileSync url
					else
						res.end fs.readFileSync url
				catch e
					console.error e.message
					res.end e.message
	catch e
		console.error e.message
		res.end e.message

).listen(8000);

console.log 'server started'
