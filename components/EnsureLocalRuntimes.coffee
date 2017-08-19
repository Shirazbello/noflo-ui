noflo = require 'noflo'
uuid = require 'uuid'

iframeAddress = 'https://noflojs.org/noflo-browser/everything.html?fbp_noload=true&fbp_protocol=iframe'

ensureOneIframeRuntime = (runtimes) ->
  for runtime in runtimes
    # Check that we don't have the iframe runtime already
    if runtime.protocol is 'iframe' and runtime.address is iframeAddress
      # Update 'last seen' property
      runtime.seen = Date.now()
      return runtime
  iframeRuntime =
    label: 'NoFlo HTML5 environment'
    id: uuid()
    protocol: 'iframe'
    address: 'https://noflojs.org/noflo-browser/everything.html?fbp_noload=true&fbp_protocol=iframe'
    type: 'noflo-browser'
    seen: Date.now()
  return iframeRuntime

ensureMicroFloRuntimePerSerialDevice = (runtimes, callback) ->
  try
    microflo = require 'microflo'
  catch e
    return callback e
  return callback null unless microflo.serial.isSupported()

  microflo.serial.listDevices (devices) ->
    newRuntimes = []
    for device in devices
      rt =
        label: device
        id: uuid()
        protocol: 'microflo'
        address: 'serial://'+device
        type: 'microflo'
        seen: Date.now()
      newRuntimes.push rt
    return callback newRuntimes

exports.getComponent = ->
  c = new noflo.Component
  c.inPorts.add 'in',
    datatype: 'array'
  c.outPorts.add 'out',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    async: true
    forwardGroups: false
  , (data, groups, out, callback) ->
    data = [] unless data
    iframeRuntime = ensureOneIframeRuntime data
    if iframeRuntime
      out.send iframeRuntime
    ensureMicroFloRuntimePerSerialDevice data, (err, runtimes) ->
      console.log err if err
      return callback() unless runtimes
      for runtime in runtimes
        out.send runtime
      do callback
