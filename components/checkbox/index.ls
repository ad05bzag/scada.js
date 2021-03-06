require! 'aea': {pack, merge, sleep}

Ractive.components['checkbox'] = Ractive.extend do
    template: RACTIVE_PREPARSE('index.pug')
    isolated: yes
    oninit: ->
        if @get \class .index-of(\transparent)  > -1
            @set \transparent, yes

        @sync = @find-component \sync
        if @sync
            @sync.on \receive, (event, msg) ~>
                @set \state, if msg.payload then \checked else \unchecked

    onrender: ->
        __ = @

        logger = @root.find-component \logger
        console.error "No logger component is found!" unless logger

        @observe \checked, (_new, _old) ~>
            __.set \state, if _new then 'checked' else 'unchecked'
            if @sync
                @sync.actor.send (@get \state), (@sync.get \topic)

        @on do
            toggleChecked: ->
                __.set \timestamp, Date.now!
                if @has-event 'statechange'
                    if __.get(\checked) then
                        [curr-state, intended-state] = <[ checked unchecked ]>
                    else
                        [curr-state, intended-state] = <[ unchecked checked ]>
                    parameter = __.get(\value)

                    __.fire \statechange curr-state, intended-state, parameter
                else
                    __.toggle \checked

            state: (event, s, msg, callback ) ->
                self-disabled = no

                @set \prevState, @get \state

                if s in <[ checked ]>
                    __.set \state, \checked
                    __.set \checked, yes

                if s in <[ unchecked ]>
                    __.set \state, \unchecked
                    __.set \checked, no

                if s in <[ doing ]>
                    __.set \state, \doing
                    self-disabled = yes

                if s in <[ error ]>
                    console.warn "scadajs: Deprecation: use \"checkbox.fire \\error\" instead"
                    @fire \error, msg, callback

                __.set \selfDisabled, self-disabled

        @error = (msg, callback) ~>
            msg = if typeof! msg is \String
                {message: msg}
            else if not msg
                {message: '(message is empty)'}
            else
                msg

            msg = msg `merge` {
                title: msg.title or 'Error'
                icon: "warning sign"
            }

            @set \reason, msg.message
            @set \selfDisabled, no
            @set \state, @get \prevState
            action <- logger.fire \showDimmed, {}, msg, {-closable}
            #console.log "error has been processed by ack-button, action is: #{action}"
            callback action if typeof! callback is \Function



    data: ->
        checked: no
        style: ''
        reason: ''
        type: "default"
        value: ""
        class: ""
        disabled: no
        self-disabled: no
        enabled: yes
        angle: 0
        tooltip: ''
        timestamp: null
        state: null
        prev-state: null
        transparent: no
        msg: null
