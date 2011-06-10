#!/usr/bin/env /usr/local/bin/coffee

sys = require 'sys'
fs = require 'fs'
URL = require 'url'
http = require 'http'
qs = require 'querystring'
util = require 'util'
coffee = require 'coffee-script'
exec = require('child_process').exec

trim = (str)->str.replace(/(^\s+|\s+$)/,'')

processData = (data, method, response) ->
	params = qs.parse data
	console.dir "processing req #{method}:#{params}"
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
						fl = fs.readdirSync(params.path)
						for f in fl
							try
								stats = fs.statSync "#{params.path}/#{f}"
								list[f] = if stats.isDirectory() then 'directory' else 'file'
							catch e
								console.err e
						out = JSON.stringify list 
						# console.log("got file list:#{out.toString()}")
					when 'log'
						console.log "LOG:#{params.message}"
						out = ""
					when 'getHome'
						out = JSON.stringify {home:home}
			when 'PUT'
				switch params.action
					when null
						out = "specify the action jerko"
					when 'save'
						if params.fn is null
							out = "filename missing"
						else if params.content is null
							out = "no file content found!"
						else
							console.log "saving file #{params.fn}"
							fs.writeFile params.fn, params.content, (err) ->
								if err?
									console.log err
									out = "err"
								else 
									out = "save complete"
									console.log out
			
			
	catch e
		console.log e.stack
		out = e.message
		
	response.end out
	

############ MAIN ############

home = null;
exec 'cd;pwd',(e,so,se)->
	home = trim(so)
	console.log home

	
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
