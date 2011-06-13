window.onload = ->
	$ = (element) ->
		document.getElementById element
	canvas = new window.Viewer($('canvas'));
	$('canvas').bind "tap", (params) ->
		canvas.displayPoint(params.first.x, params.first.y, "FF0000")
		
	$('canvas').bind "tap,tap", (params) ->
		
		canvas.displayLine(params.first.x, params.first.y, params.second.x, params.second.y, "#0000AA")
		
	$('canvas').bind "tap,tap,tap", (params) ->
		canvas.displayPoint(params.first.x, params.first.y, "#FF0000")
		canvas.displayPoint(params.second.x, params.second.y, "#FF0000")
		canvas.displayPoint(params.third.x, params.third.y, "#FF0000")
		canvas.displayLine(params.first.x, params.first.y, params.second.x, params.second.y, "#0000AA")
		canvas.displayLine(params.second.x, params.second.y, params.third.x, params.third.y, "#0000AA")
		canvas.displayLine(params.first.x, params.first.y, params.third.x, params.third.y, "#0000AA")


	
	$('canvas').bind "right", (params) ->
		draw(params)
		
	$('canvas').bind "left", (params) ->
		draw(params)
		
	$('canvas').bind "up", (params) ->
		draw(params)
					
	$('canvas').bind "down", (params) ->
		draw(params)

	started = false
	c = $("canvas")
	context = c.getContext('2d')	
	context.lineWidth = 2
	context.strokeStyle = "rgba(0,0,0,1)"
	previousX = 0
	previousY = 0
	draw = (params) ->
		if (!started)
			previousX = params.first.x
			previousY = params.first.y
			context.beginPath();
			context.moveTo(params.first.x, params.first.y);
			started = true;
		else
			context.quadraticCurveTo(params.first.startX, params.first.startY, params.first.x, params.first.y);
			##context.lineTo(params.first.x, params.first.y);
			context.stroke();
			previousX = params.first.x
			previousY = params.first.y
	
	$('canvas').bind "dragend", (params) ->
		started = false;		
		context.closePath();


	$('canvas').bind "all", (a, params) ->
		$('debug').innerHTML += a + "<br>"