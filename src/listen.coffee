module.exports = expose: (options) -> new @Promise (resolve) =>
  server = @io.httpServer || @io
  server.listen options.port, options.host, =>
    if options.host
      str = "http://#{options.host}:#{options.port}/"
    else
      str = "port: #{options.port}"
    console.log "samjs server listening on #{str}"
    resolve()