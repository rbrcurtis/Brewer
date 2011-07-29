#members
@input = $('#input')
@html = $('html')
@debugDiv = $('#debug')
@editor = ace.edit "input"
@output = ace.edit "output"
@timer = null
dialogIsOpen = false
dialog = $("<table id='dialog'></table>")
@path = null
@file = null

#functions
trim = (str)->str.replace(/(^\s+|\s+$)/,'')


compile = (updateTitle = true) ->
	try
		compiled = CoffeeScript.compile(@editor.getSession().getValue(), bare:on)
		@output.getSession().setValue(compiled)
		@debugDiv.html "-"
		if updateTitle and !document.title.match /^\*/
			document.title = "* #{document.title}"
	catch error
		msg = error.message
		@debugDiv.html("<span style='color:red'>#{msg}</span>")
		# line = msg.match(/line ([0-9]+)/)
		# if line isnt null and line.length > 0
			


sendReq = (data,method,callback)->
	$.ajax({
		type:method,
		url:"http://localhost:8000/"
		data:data
		timeout:3000
		success:(data, text)->
			# @output.getSession().setValue data.toString()
			#if data isnt null then debug "#{data.toString()}:#{text}"
			if callback? then callback data
		error:(data, err)->
			debug "REQUEST ERROR:#{data.status},#{data.statusText}"

	})

serverLog = (msg) ->
	sendReq {action:'log',message:msg}, "POST"


debug = (msg) ->
	if typeof msg is 'object'
		for key,val of msg
			debug "\t#{key}=#{val}"
	else
		@debugDiv.html "#{@debugDiv.html()}<br/>\n#{msg}"
	# serverLog msg
	@debugDiv.scrollTop @debugDiv[0].scrollHeight


jQuery.fn.center = ->
    @css("position","absolute")
    @css("top", ( $(window).height() - this.height() ) / 2+$(window).scrollTop() + "px")
    @css("left", ( $(window).width() - this.width() ) / 2+$(window).scrollLeft() + "px")
    return this;


closeDialog = ->
	if dialogIsOpen
		dialog.empty()
		dialog.remove()
		dialogIsOpen = false


showFileDialog = (p, callback) ->
	@path = p
	@path = @path.replace "//", "/"
	dialogIsOpen = true
	debug "show save window:#{@path}"
	sendReq {action:'fileList',path:@path}, 'POST', (data) ->
		# debug "save window file list:#{data}"
		table = $("<table cellspacing='2' cellpadding='2' id='filebrowser'></table>")
		table.append("<colgroup><col span='1'/><col span='1' style='width:100px;'/></colgroup>")
		table.append("<thead><tr><th>file/dir name</th><th>type</th></tr></thead>")

		do ->
			if @path is "/" then return
			up = @path
			if up isnt "/" and up.match "/$"
				up = up.substring 0, up.length-1
			
			if up.lastIndexOf("/")>=0
				up = up.substring 0, up.lastIndexOf("/")
			
			if up is "" then up = "/"
		
			debug "up:#{up}"
			
			#note that if up = / then up will continue to = /

			cb = (file) -> 
				closeDialog()
				showFileDialog(up, callback)
			
			table.append(
				$("<tr></tr>")
					.append(
						$("<td>..</td>").click(->cb(up))
					).append(
						$("<td>directory</td>").click(->cb(up))
					)
			)

		for file,type of data
			do (file, type) ->
				#create callback function for clicking that row of the table
				if type is 'directory'
					cb = (file) -> 
						closeDialog()
						showFileDialog("#{@path}/#{file}", callback)
				else if type is 'file'
					cb = (file) ->
						closeDialog()
						callback("#{@path}/#{file}")
					
				table.append(
					$("<tr></tr>")
						.append(
							$("<td>#{file}</td>").click(->cb(file))
						).append(
							$("<td>#{type}</td>").click(->cb(file))
						)
				)
				
		#current path box
		dialog.append(
			$("<tr></tr>").append("<td colspan='2' align='center'>#{@path}</td>")
		)

		
		#filename input box
		enterBind = (e) =>
			code = if e.keyCode then e.keyCode else e.which
			if code is 13
				debug "enter pressed for "+@path+'/'+$('#newFN').val()
				save @path+'/'+$('#newFN').val()
				closeDialog()

		dialog.append(
			$("<tr></tr>").append("<td>New File Name:</td>").append(
				$("<td></td>").append(
					$("<input type='text' id='newFN' style='width:95%'/>").bind("keydown",enterBind)
				)
			)
		)


		dialog.append(
		    $("<tr></tr>").append(
		        $("<td colspan='3'></td>").append(
		            $("<div style='max-height:400px;overflow-y:scroll;'></div>").append(table)
		        )
		    )
		)
		@html.append dialog
		dialog.center()


save = (@file) ->
	debug "saving #{@file}"
	@path = file.substring(0,file.lastIndexOf('/'))
	@fn = file.substring(file.lastIndexOf('/')+1)
	document.title = "* "+fn
	sendReq {action:'save', content:@editor.getSession().getValue(), fn:file}, 'POST', (data,err) ->
		# debug 'save returned'
		if err then debug err
		debug data
		if m = document.title.match /^\* (.*)/
			document.title = m[1]
		
open = (file) ->
	if @file?
		window.open "http://localhost:8000?file=#{file}"
	else
		sendReq {action:'open', content:@editor.getSession().getValue(), fn:file}, 'POST', (data,err) ->
			# debug 'open returned'
			if err then debug err
			# debug data
			# for key, val of data
			# 	debug "\t#{key}=#{val}"
			@editor.getSession().setValue(data.content)
			compile(false)
			@file = file
			@path = file.substring(0,file.lastIndexOf('/'))
			@fn = file.substring(file.lastIndexOf('/')+1)
			document.title = fn

close = ->
	if @file?
		sendReq {action:'close', fn:@file}, 'POST'
		#no callback because the window will be closed
		

isBetweenDoubleQuotes = ->
	pos = editor.getCursorPosition()
	line = editor.getSession().getLine(pos.row)
	i = line.indexOf('"')
	j = line.lastIndexOf('"')
	if i>-1 and j>-1 and i<pos.column<=j
		between = true
	else between = false

	return between

isBetweenAnyQuotes = ->
	pos = editor.getCursorPosition()
	line = editor.getSession().getLine(pos.row)
	i = line.indexOf('"')
	j = line.lastIndexOf('"')
	if i is -1 and j is -1
		i = line.indexOf("'")
		j = line.lastIndexOf("'")
	if i>-1 and j>-1 and i<pos.column<=j
		between = true
	else between = false

	return between


surroundSelection = (before, after) ->
	s = editor.getSelectionRange()
	start = s.start
	end = s.end
	selection = editor.selection
	pos = selection.getCursor()
	selection.clearSelection()
	selection.moveCursorToPosition end
	editor.insert after
	selection.moveCursorToPosition start
	editor.insert before
	# if start.column isnt end.column
	start.column = start.column+before.length
	end.column = end.column+before.length
	pos.column = pos.column+before.length
	if pos.column is start.column
		selection.setSelectionRange(start:start,end:end)
	else
		selection.setSelectionRange(end:end,start:start)

getConfig = (cb) ->
	sendReq {action:"getConfig"}, 'POST', (data) ->
		@path = data.config.home
		debug "path is #{@path}"
		if cb? then cb(data)


if m = window.location.href.match /^[^?]+?.*file=([^&]+)/
	if window.referrer isnt "http://localhost:8000/" and window.referrer isnt undefined
		alert "HAX! #{window.referrer}"

	else if m[1] isnt "none"
			open m[1]

	else
		getConfig()
else
	getConfig (data) ->
		if data.config.lastFiles?
			for i,f of data.config.lastFiles
				if i is "0"
					open f
				else 
					window.open "http://localhost:8000?file=#{f}"



#main 
@editor.getSession().on 'change', ->
	if @timer?
		clearTimeout @timer
		@timer = null
	@timer = setTimeout ( ->compile() ), 500
	
@output.getSession().on 'change', ->
	o = $("#output .ace_scroller")
	setTimeout ( -> o.scrollLeft 0 ), 500
	

@html.bind 'keypress keydown', (e) =>
	code = if e.keyCode then e.keyCode else e.which
	if code is 27 and dialogIsOpen
		closeDialog()
	if e.metaKey || e.ctrlKey
		switch code
			when 69 #E - debugging
				debug ""
			when 78 #N - new
				window.open "http://localhost:8000?file=none"

			when 79 #O
				showFileDialog(@path, open)

			when 83 #S
				if @file? and !e.shiftKey
					save(@file)
				else
					showFileDialog(@path, save)

			when 87 #W - close tab
				close()
				return
				
			when 191 #/
				e.preventDefault()
				e.stopPropagation()
			
				s = editor.getSelectionRange()
				start = s.start
				end = s.end
				selection = editor.selection
				pos = selection.getCursor()
				
				commenting = []
				for i in [start.row..end.row]
					selection.moveCursorToPosition(row:i,column:0)
					selection.clearSelection()
					if editor.getSession().getLine(i).charAt(0) is '#'
						commenting[i] = false
						editor.removeRight()
					else
						commenting[i] = true
						editor.insert "#"
				
				if commenting[pos.row] then pos.column++ else pos.column--
				if commenting[start.row] and start.column isnt 0 then start.column++ else start.column--
				if commenting[end.row] then end.column++ else end.column--


				if pos.row is start.row
					debug "move to start:#{pos.row}"
					selection.moveCursorToPosition(pos)
					selection.setSelectionRange(start:end,end:start)
				else
					debug "move to end:#{pos.row}"
					selection.moveCursorToPosition(pos)
					selection.setSelectionRange(start:start,end:end)

			else return

		e.preventDefault()
		e.stopPropagation()
		# debug code
		# return false


@input.bind 'keydown', (e) ->
	code = if e.keyCode then e.keyCode else e.which
	if code is 27 and dialogIsOpen
		closeDialog()
	if !e.metaKey and !e.ctrlKey and !e.altKey
		debug code
		if e.shiftKey
			switch code
				when 51 # #
					if isBetweenDoubleQuotes()
						e.preventDefault()
						e.stopPropagation()
						surroundSelection '#{','}'
					else return
				when 57 # (
					if !isBetweenAnyQuotes()
						e.preventDefault()
						e.stopPropagation()
						surroundSelection '(',')'
					else return
				when 219 # {
					if !isBetweenAnyQuotes()
						e.preventDefault()
						e.stopPropagation()
						surroundSelection '{','}'
					else return
				else return
		else
			switch code
				when 219 # [
					if !isBetweenAnyQuotes()
						e.preventDefault()
						e.stopPropagation()
						surroundSelection '[',']'
					else return





#@editor.setTheme "ace/theme/twilight"

CoffeeMode = require("ace/mode/coffee").Mode
@editor.getSession().setMode(new CoffeeMode())

JavaScriptMode = require("ace/mode/javascript").Mode
@output.getSession().setMode(new JavaScriptMode())
@output.setReadOnly true

@editor.focus()

if @editor.getSession().getValue()?
	compile()


