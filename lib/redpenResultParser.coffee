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

    for val in result[0].errors
      val["atomErrorEndPositionRow"] = val["lineNum"]
      val["atomErrorEndPositionCollum"] = 0

      if val["errorEndPosition"]?
        splited = val["errorEndPosition"].split(",")
        if splited.length is 2
          val["atomErrorEndPositionRow"] = splited[0]
          val["atomErrorEndPositionCollum"] = splited[1]

    return result
