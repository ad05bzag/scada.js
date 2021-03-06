require! 'prelude-ls': {flatten, join, split}
require! 'nano'
require! './debug-log': {logger}
require! 'colors': {bg-red, bg-green, bg-yellow}
require! './packing': {pack}
require! './sleep' : {sleep}
require! './couch-helpers': {pack-id, unpack-id}
export class CouchNano
    (@cfg) ~>
        @cookie = null
        @nano = nano @cfg.url
        @log = new logger "db:#{@cfg.database}"
        @username = @cfg.user.name
        @password = @cfg.user.password
        @db-name = @cfg.database

    pack-id: pack-id
    unpack-id: unpack-id
    
    connect: (callback) ->
        @log.log "Authenticating as #{@username}"
        err, body, headers <~ @nano.auth @username, @password
        if err
            #@log.log "error while authenticating: ", err
            return callback err, null

        if headers
            if headers['set-cookie']
                @use-cookie that
                return callback null, 'ok'

        @log.log bg-red "unexpected response."
        return callback {text: "unexpected response"}, null

    use-cookie: (cookie) ->
        #@log.log bg-yellow "Using new cookie: #{cookie}"
        @db = nano do
            url: @cfg.url
            cookie: cookie
        @request = @db.request

        # for debugging purposes
        /*
        # make cookie a garbage, thus break the session
        <~ sleep 5000ms
        @db = nano do
            url: @cfg.url
            cookie: "garbage"
        @request = @db.request
        */


    put: (doc, callback) ->
        err, res, headers <~ @request do
            db: @db-name
            body: doc
            method: \post

        if err => if err.statusCode is 401
            # we are unauthorized, try to login again
            @log.log bg-yellow "Trying to re-login"
            @connect (err) ~>
                unless err
                    @log.log bg-green "logged in again."
                    @put doc, callback
            return

        if headers? => if headers['set-cookie'] => @use-cookie that

        err = {reason: err.reason, name: err.name, message: err.reason} if err
        callback err, res

    get: (doc-id, opts, callback) ->
        [callback, opts] = [opts, {}] if typeof! opts is \Function

        err, res, headers <~ @request do
            db: @db-name
            doc: doc-id
            qs: opts

        if err => if err.statusCode is 401
            # we are unauthorized, try to login again
            @log.log bg-yellow "Trying to re-login"
            @connect (err) ~>
                unless err
                    @log.log bg-green "logged in again."
                    @get doc-id, opts, callback
            return

        if headers? => if headers['set-cookie'] => @use-cookie that

        err = {reason: err.reason, name: err.name, message: err.reason} if err
        callback err, res

    all: (opts, callback) ->
        [callback, opts] = [opts, {}] if typeof! opts is \Function

        err, res, headers <~ @request do
            db: @db-name
            path: '_all_docs'
            qs: opts

        if err => if err.statusCode is 401
            # we are unauthorized, try to login again
            @log.log bg-yellow "Trying to re-login"
            @connect (err) ~>
                unless err
                    @log.log bg-green "logged in again."
                    @all opts, callback
            return

        if headers? => if headers['set-cookie'] => @use-cookie that

        err = {reason: err.reason, name: err.name, message: err.reason} if err
        callback err, res?.rows

    view: (ddoc-viewname, opts, callback) ->
        # usage:
        #    view 'graph/tank', {my: option}, callback
        #    view 'graph/tank', callback

        # ------------------------------------
        # normalize parameters
        # ------------------------------------
        [ddoc, viewname] = split '/', ddoc-viewname
        if typeof! opts is \Function
            callback = opts
            opts = {}

        err, res, headers <~ @_view ddoc, viewname, {type: \view}, opts

        if err => if err.statusCode is 401
            # we are unauthorized, try to login again
            @log.log bg-yellow "Trying to re-login"
            @connect (err) ~>
                unless err
                    @log.log bg-green "logged in again."
                    @view ddoc-viewname, opts, callback
            return

        if headers? => if headers['set-cookie'] => @use-cookie that

        err = {reason: err.reason, name: err.name, message: err.reason} if err
        #console.log "couch-nano got #{pack res ?.length} bytes"
        callback err, res

    _view: (ddoc, viewName, meta, qs, callback) ->
        relax = @request
        dbName = @db-name
        ``
        var view = function (ddoc, viewName, meta, qs, callback) {
          if (typeof qs === 'function') {
            callback = qs;
            qs = {};
          }
          qs = qs || {};

          var viewPath = '_design/' + ddoc + '/_' + meta.type + '/'  + viewName;

          // Several search parameters must be JSON-encoded; but since this is an
          // object API, several parameters need JSON endoding.
          var paramsToEncode = ['counts', 'drilldown', 'group_sort', 'ranges', 'sort'];
          paramsToEncode.forEach(function(param) {
            if (param in qs) {
              if (typeof qs[param] !== 'string') {
                qs[param] = JSON.stringify(qs[param]);
              } else {
                // if the parameter is not already encoded, encode it
                try {
                  JSON.parse(qs[param]);
                } catch(e) {
                  qs[param] = JSON.stringify(qs[param]);
                }
              }
            }
          });

          if (qs && qs.keys) {
            var body = {keys: qs.keys};
            delete qs.keys;
            return relax({
              db: dbName,
              path: viewPath,
              method: 'POST',
              qs: qs,
              body: body
            }, callback);
          } else {
            var req = {
              db: dbName,
              method: meta.method || 'GET',
              path: viewPath,
              qs: qs
            };

            if (meta.body) {
              req.body = meta.body;
            }

            return relax(req, callback);
          }
        }
        ``
        view(ddoc, viewName, meta, qs, callback)


if require.main is module
    test = new CouchNano do
        user:
            name: 'theseencedidesceepediven'
            password: '09b8c87f79bd2072dc7cb20bad67138f578d7a03'
        url: "https://aktos.cloudant.com"
        database: \test
    <~ test.connect

    const i = 35
    count = 10
    _tmp = i

    ->
        <~ :lo(op) ~>
            err, res <~ test.put do
                _id: "hello#{_tmp++}"
                val: 1

            return test.log.err "error while putting document: ", err if err
            test.log.log "success: ", res

            return op! if _tmp > i + count
            lo(op)

        test.log.log "all documents are put"

    _tmp = i
    <~ :lo(op) ~>
        err, res <~ test.get "hello#{_tmp++}"
        return test.log.err "error while getting document: ", err if err
        test.log.log "success: ", res

        return op! if _tmp > i + count
        lo(op)

    test.log.log "all documents are read"
