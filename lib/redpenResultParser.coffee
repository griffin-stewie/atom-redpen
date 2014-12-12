parser = require 'xml2json'

module.exports =
  parse: (stdout) ->
    lines = stdout.split(/\n/)
    xmlLines = lines.filter (line) ->
      if /^\</.test(line)
        return line
      else
        return null

    xmlString = "<?xml version='1.0' encoding='UTF-8'?>" + xmlLines.join("\n")
    result = JSON.parse(parser.toJson(xmlString))

    return result
