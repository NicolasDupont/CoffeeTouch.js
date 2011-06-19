##	Analyser
## 		Analyse and trigger events sent by the Event Router
##
## Copyright (c) 2011
## Publication date: 06/17/2011
##		Pierre Corsini (pcorsini@polytech.unice.fr)
##		Nicolas Dupont (npg.dupont@gmail.com)
##		Nicolas Fernandez (fernande@polytech.unice.fr)
##		Nima Izadi (nim.izadi@gmail.com)	
##		And supervised by Raphaël Bellec (r.bellec@structure-computation.com)
##
## Permission is hereby granted, free of charge, to any person obtaining a 
## copy of this software and associated documentation files (the "Software"),
## to deal in the Software without restriction, including without limitation
## the rights to use, copy, modify, merge, publish, distribute, sublicense, 
## and/or sell copies of the Software, and to permit persons to whom the Software 
## is furnished to do so, subject to the following conditions:
## 
## The above copyright notice and this permission notice shall be included in
## all copies or substantial portions of the Software.
## 
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
## OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
## WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
## IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

class Analyser
	## Create an analyser object with total number of fingers and an array of all fingers as attribute
	constructor: (@totalNbFingers, @targetElement) ->
		@fingersArray = {} ## Hash with fingerId: fingerGestureObject
		@fingers = [] ## Array with all fingers		
		@firstAnalysis = true ## To know if we have to init the informations which will be returned
		@informations = {} ## All informations which will be send with the event gesture
		@informations = {} ## Informations corresponding to all fingers
		@informations.fingers = []
		@informations.firstTrigger = true
		date = new Date()
		@fingerArraySize = 0
		@informations.timeStart = date.getTime()

	## Notify the analyser of a gesture (gesture name, fingerId and parameters of new position etc)
	notify: (fingerID, gestureName, @eventObj) ->
		@informations.rotation = @eventObj.global.rotation 
		@informations.scale = @eventObj.global.scale
		date = new Date()
		@informations.timeElapsed = date.getTime() - @informations.timeStart
		if @fingersArray[fingerID]?
			@fingersArray[fingerID].update gestureName, @eventObj
		else
			@fingersArray[fingerID] =  new FingerGesture(fingerID, gestureName, @eventObj)
			@fingers.push @fingersArray[fingerID]
			@fingerArraySize++
		## Analyse event only when it receives the information from each fingers of the gesture.
		@analyse @totalNbFingers if @fingerArraySize is @totalNbFingers
	
	analyse: (nbFingers) ->
		@init() if @firstAnalysis
		@gestureName = []
		@gestureName.push finger.gestureName for finger in @fingers
		@targetElement.trigger @gestureName, @informations
		@generateGrouppedFingerName()
		@triggerDrag()
		@triggerFixed()
		@triggerFlick()
		@informations.firstTrigger = false if @informations.firstTrigger
	
	## Sort fingers and initialize some informations that will be triggered to the user
	## Is called before analysis
	init: ->
		## Sort fingers. Left to Right and Top to Bottom
		@fingers = @fingers.sort (a,b) ->
			return a.params.startY - b.params.startY if Math.abs(a.params.startX - b.params.startX) < 15
			return a.params.startX - b.params.startX
		@informations.nbFingers = @fingers.length
		## For each finger, assigns to the information's event the information corresponding to this one.
		for i in [0..@fingers.length - 1]
			@informations.fingers[i] = @fingers[i].params
		@firstAnalysis = false
	
	## Trigger all names related to the drag event
	triggerDrag: -> 
		if @gestureName.contains "drag"
			@triggerDragDirections()
			if @gestureName.length > 1
				@triggerPinchOrSpread()
				@triggerRotation()

	## Trigger all names related to the drag direction
	triggerDragDirections: ->
		gestureName = []
		gestureName.push finger.params.dragDirection for finger in @fingers
		@targetElement.trigger gestureName, @informations if !gestureName.contains "unknown"

	## Test if the drag is a pinch or a spread
	triggerPinchOrSpread: ->
		# The scale is already sent in the event Object
		# @informations.scale = @calculateScale()
		## Spread and Pinch detection
		if @informations.scale < 1.1
			@targetElement.trigger "#{digit_name(@fingers.length)}:pinch", @informations
			@targetElement.trigger "pinch", @informations
		else if @informations.scale > 1.1
			@targetElement.trigger "#{digit_name(@fingers.length)}:spread", @informations
			@targetElement.trigger "spread", @informations


	## Trigger all names related to the fixed event
	triggerFixed: ->
		if @gestureName.length > 1 and @gestureName.contains "fixed"
			dontTrigger = false
			gestureName = []
			for finger in @fingers
				if finger.gestureName == "drag" and finger.params.dragDirection == "triggerDrag"
					dontTrigger = true
					break
				if finger.gestureName == "drag" then gestureName.push finger.params.dragDirection else gestureName.push "fixed"
			if !dontTrigger
				@targetElement.trigger gestureName, @informations
			
	## Trigger all names related to the flick event
	triggerFlick: ->
		if @gestureName.contains "dragend"
			gestureName1 = []
			gestureName2 = []
			dontTrigger = false
			for finger in @fingers
				if finger.params.dragDirection == "unknown" then dontTrigger = true
				if finger.isFlick
					gestureName1.push "flick:#{finger.params.dragDirection}"
					gestureName2.push "flick"
				else
					gestureName1.push finger.params.dragDirection
					gestureName2.push finger.params.dragDirection
			if !dontTrigger
				@targetElement.trigger gestureName1, @informations
				@targetElement.trigger gestureName2, @informations
		

	## Trigger if it is a rotation, and specify if it is clockwise or counterclockwise
	triggerRotation: -> 
		if !@lastRotation?
			@lastRotation = @informations.rotation
		rotationDirection = ""
		if @informations.rotation > @lastRotation then rotationDirection = "rotate:cw" else rotationDirection = "rotate:ccw"	
		#@lastRotation = @informations.rotation

		
		@targetElement.trigger rotationDirection, @informations
		@targetElement.trigger "rotate", @informations
		@targetElement.trigger "#{digit_name(@fingers.length)}:#{rotationDirection}", @informations
		@targetElement.trigger "#{digit_name(@fingers.length)}:rotate", @informations

	## Trigger combination of names which are like "one:....,two:..." etc.
	generateGrouppedFingerName: -> 
		gestureName = [] 
		gestureNameDrag = []
		triggerDrag = false
		gestures = 
			tap: 0
			doubletap: 0
			fixed: 0
			fixedend: 0
			drag: 0
			dragend: {n: 0, fingers: []}
			dragDirection:
				up: 0
				down: 0
				left: 0
				right: 0
				drag: 0
		
		for finger in @fingers
			switch finger.gestureName
				when "tap" then gestures.tap++
				when "doubletap" then gestures.doubletap++
				when "fixed" then gestures.fixed++
				when "fixedend" then gestures.fixedend++
				when "dragend" 
					gestures.dragend.n++
					gestures.dragend.fingers.push finger
				when "drag"
					gestures.drag++
					switch finger.params.dragDirection
						when "up" then gestures.dragDirection.up++
						when "down" then gestures.dragDirection.down++
						when "right" then gestures.dragDirection.right++
						when "left" then gestures.dragDirection.left++
		for gesture of gestures
			## For the flick, I consider that if two drag end has been done at the same time and one of them is
			## a flick, both of them where flick
			if gesture == "dragend" and gestures[gesture].n > 0
				for finger in gestures[gesture].fingers
					if finger.isFlick
						gestureName.push "#{digit_name(gestures[gesture].n)}:flick" 
						gestureNameDrag.push "#{digit_name(gestures[gesture].n)}:flick:#{finger.params.dragDirection}"
						triggerDrag = true
						break
			else if gesture == "dragDirection"
				for gestureDirection of gestures[gesture]
					if gestures[gesture][gestureDirection] > 0
						gestureNameDrag.push "#{digit_name(gestures[gesture][gestureDirection])}:#{gestureDirection}" 
						triggerDrag = true
			else if gestures[gesture] > 0
				gestureName.push "#{digit_name(gestures[gesture])}:#{gesture}"
				gestureNameDrag.push "#{digit_name(gestures[gesture])}:#{gesture}" if gesture != "drag"

		@targetElement.trigger gestureName, @informations if gestureName.length > 0
		@targetElement.trigger gestureNameDrag, @informations if triggerDrag
