include docs in views -> add "?include_docs=true" parameter in the query

## Security per database:

{{db}}/_security:

{
  "_id": "_security",
  "couchdb_auth_only": true,
  "admins": {
    "names": [
      "demeter"
    ],
    "roles": [
      "_admin"
    ]
  },
  "members": {
    "names": [
      "batman",
      "robin",
      "mahmut1"
    ],
    "roles": [
      "cici"
    ]
  }
}

## List example

views:
    get-orders:
        map: (doc) ->
            if doc.type is \order
                emit doc._id, 1

lists:
    my-orders: (head, req) ->
        # see : https://demeter.cloudant.com/cicimeze/_design/orders/_list/myOrders/getOrders?include_docs=true
        provides \html, ->
            html = """
                <html>
                    <body>
                        <ul>
                """
            while row = get-row!
                html += "<li>#{row.key} : #{row.doc.client}"
                html += "    <ol>"
                for i in row.doc.entries
                    html += "<li>#{i.type}</li>"
                html += "    </ol>"
                html += "</li>"

            html += """
                        </ul>
                    </body>
                </html>
                """

## Replication:



Design documents will only replicate if you are authenticated as an admin, or a db admin, on your target. Try something like setting your target as

http://admin:password@projects.blurrcat.com/couchdb/soup


create a document in _replicator db, like so:

{
  "_id": "197d5186-402d-4de4-8d4b-d3acf90157b7",
  "source": "https://theadmin:theadminpassword@example.cloudant.com/sourcedb",
  "target": "http://foo:bar@127.0.0.1/targetdb",
  "create_target": true,
  "continuous": true
}
