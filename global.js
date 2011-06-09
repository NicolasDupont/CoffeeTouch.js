(function() {
  /*
  ## The bind, unbind and trigger function have been taken from Backbone Framework.
  ## The bind function has been changed
  */  var $;
  Object.prototype.bind = function(eventName, callback) {
    var calls, list;
    calls = this._callbacks || (this._callbacks = {});
    list = this._callbacks[eventName] || (this._callbacks[eventName] = []);
    list.push(callback);
    /*
    	*/
    /*
    
    	that = this
    	## Initializing specific properties for this given object
    	@touchProperties = {};
    	@touchProperties.dateLastTouch = 0
    	
    	this.addEventListener 'touchstart', (event) ->
    		@touchProperties.isTouched = true
    
    		## Tap
    		## If a simple tap is done, trigger "tap"
    		this.trigger "tap"
    
    		## Double Tap
    		## If two tap are separated from 500 ms, trigger "doubletap"
    		_t = (new Date()).getTime()
    		if (_t - @touchProperties.dateLastTouch) < 1000
    			this.trigger "doubletap"
    		@touchProperties.dateLastTouch = _t
    		
    		## Press
    		setTimeout(-> 
    			if that.touchProperties.isTouched == true
    				that.trigger "press"
    		, 5000);
    
    	
    	for evtName in ['touchcancel','touchend']
    		@touchProperties.isTouched = false
    	
    	*/
    return this;
  };
  Object.prototype.unbind = function(ev, callback) {
    var calls, i, list, _i, _len;
    if (!ev) {
      this._callbacks = {};
    } else if (calls = this._callbacks) {
      if (!callback) {
        calls[ev] = [];
      } else {
        list = calls[ev];
        if (!list) {
          return this;
        }
        for (_i = 0, _len = list.length; _i < _len; _i++) {
          i = list[_i];
          if (callback === list[i]) {
            list.splice(i, 1);
            break;
          }
        }
      }
    }
    return this;
  };
  
Object.prototype.trigger =  function(ev) {
	  var list, calls, i, l;
	  if (!(calls = this._callbacks)) return this;
	  if (list = calls[ev]) {
	    for (i = 0, l = list.length; i < l; i++) {
	      list[i].apply(this, Array.prototype.slice.call(arguments, 1));
	    }
	  }
	  if (list = calls['all']) {
	    for (i = 0, l = list.length; i < l; i++) {
	      list[i].apply(this, arguments);
	    }
	  }
	  return this;
	};
;
  $ = function(element) {
    return document.getElementById(element);
  };
}).call(this);
