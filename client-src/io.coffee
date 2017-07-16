# out: ../lib/io.js
ioClient = require "socket.io-client"
module.exports = (url, options={}) ->
  unless url?
    loc = window.location
    if loc.origin?
      url = loc.origin
    else
      url = loc.protocol + "//" + loc.hostname
      url +=  ":" + loc.port if loc.port?
  return ioClient(url,options).io