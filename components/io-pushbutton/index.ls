require! './button-actor': {ButtonActor}

Ractive.components['io-pushbutton'] = Ractive.extend do
    template: '''
        <div
           class="ui button
               {{#if disabled}}disabled{{/if}}
               {{#if active}}active{{/if}}
               {{ class }}
               {{#if state === 'pressed'}}yellow
               {{elseif state == 'released'}}green
               {{else}}basic red{{/if}}
               "
           style="{{style}}"
           title="{{title}}{{tooltip}}"
            >
            {{yield}}
        </div>
        '''

    isolated: no
    onrender: ->
        topic = @get \topic
        unless topic
            console.error "topic is required"
            return

        button = $ @find \.ui.button

        turn = (state) ~>
            @set \state, \doing
            err, res <~ actor.write if state then 1 else 0
            if err
                actor.log.err "error while writing value: #{err}"
            else
                @set \state, if res.payload.curr then \pressed else \released

        # for desktop
        button.on \mousedown, ->
            turn on
            button.on 'mouseleave', -> turn off

        button.on \mouseup, ->
            turn off
            button.off 'mouseleave'

        # for touch device
        button.on 'touchstart', (e) ->
            turn on
            button.on 'touchleave', -> turn off
            e.stop-propagation!

        button.on 'touchend', (e) ->
            turn off

        actor = new ButtonActor {topic: topic}
        actor.on \data, (msg) ~>
            if msg.payload.curr?
                that = msg.payload.curr
                #actor.log.log "pushbutton Received state update: #{that}"
                @set \state, if that is 1 then \pressed else \released
                @set \curr, that

        actor.request-update topic

    data: ->
        state: \doing
