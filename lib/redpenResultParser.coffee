module.exports =
  parse: (stdout) ->
    lines = stdout.split(/\n/)
    JSONLines = lines.filter (line) ->
      if /^\[/.test(line)
        return line
      else
        return null
    JSONString = JSONLines.join("\n")
    result = JSON.parse(JSONString)
    return result
