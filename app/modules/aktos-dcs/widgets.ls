# make a singleton
class RactivePartial
  instance = null
  ~>
    instance ?:= SingletonClass!
    return instance

  class SingletonClass
    ~>
      #super ...
      @widget-inits = []
      @inits-for-document-ready = []

    register: (widget-init) ->
      #console.log "new widget registered: ", widget-init
      @widget-inits ++= [widget-init]

    register-for-document-ready: (widget-init) ->
      #console.log "new widget registered: ", widget-init
      @inits-for-document-ready ++= [widget-init]

    init: ->
      #console.log "initializing ractive partials..."
      for func in @widget-inits
        #console.log "widget init: ", func
        func!
        
    init-for-document-ready: ->   
      #console.log "initializing ractive partials..."
      for func in @inits-for-document-ready
        #console.log "widget init: ", func
        func!
        
        
get-ractive-var = (jquery-elem, ractive-variable) -->
  app = RactiveApp!get!
  ractive-node = Ractive.get-node-info jquery-elem.get 0
  value = (app.get ractive-node.\keypath)[ractive-variable]
  #console.log "ractive value: ", value
  return value

set-ractive-var = (jquery-elem, ractive-variable, value) -->
  app = RactiveApp!get!
  ractive-node = Ractive.get-node-info jquery-elem.get 0
  
  if not ractive-node.\keypath
    console.log "ERROR: NO KEYPATH FOUND FOR RACTIVE NODE: ", jquery-elem
  else  
    app.set ractive-node.\keypath + '.' + ractive-variable, value
    #console.log "setting keypath: ", ractive-node.\keypath
    #console.log "setting keypath: ", ractive-node
    #console.log "set-ractive-var: ", app.nodes
  
class RactiveApp
  instance = null
  ~>
    instance ?:= SingletonClass!
    return instance

  class SingletonClass
    ~>
      #super ...
      @ractive-app = null

    set: (ractive-app) ->
      #console.log "new widget registered: ", widget-init
      @ractive-app = ractive-app
      
    get: -> 
      @ractive-app


module.exports = {
  RactivePartial, get-ractive-var, set-ractive-var, RactiveApp
}