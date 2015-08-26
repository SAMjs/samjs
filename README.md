# SAM.js

Created to connect **S**ocket.io, **A**ngularJS and **M**ongoDB.

Now it is database and view framework agnostic.

Browser client: [samjs-client](https://github.com/SAMjs/samjs-client)

#### Features

- No RESTless API - only realtime websockets
- useful defaults
- nearly no limitations
- plugable
- multiple databases simultaniously

## Getting Started
```sh
npm install --save samjs
npm install --savedev samjs-client

```
#### Simple example with koa server

```coffee
samjs = require "samjs"
koa = require("koa")()

server = require("http").createServer(koa.callback())

samjs
.plugins()
.options({config:"config.json"})
.configs({name:"item", read:true, write:true})
.models()
.startup(server)

server.listen(3000)
#to close
samjs.shutdown()

# in browser with webpack
samjs = require("samjs-client")()
samjs.config.set "item", "value"
.then ->
  #success
.catch ->
  #failed

# some other client  
samjs.config.on "item", -> #item changed
  samjs.config.get "item"
  .then (response) ->
    response == "value" # true
  .catch ->
    #failed

```

#### options
Available only through code.
Defines crucial parts of your app, should only be changed by restarting the app.
#### configs
Can be accessed through websockets
Filebased / in-memory data which defines your app, should be only changed sparsely.
#### models
Can be custom models or plugin based models.
Should be used for all data which changes on regular basis.

## Plugins
- [samjs-plugin-boilerplate](https://github.com/SAMjs/samjs-plugin-boilerplate)
- [samjs-mongo](https://github.com/SAMjs/samjs-mongo)
- [samjs-mongo-auth](https://github.com/SAMjs/samjs-mongo-auth)
