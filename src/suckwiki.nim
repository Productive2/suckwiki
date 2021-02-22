import jester
import markdown
import htmlgen
import os
import strutils
import strformat
import uri
import parseopt

const markdownExts = [".md", ".markdown", ".MD", ".MARKDOWN"]
var path = ""

proc constHtml(base: string): string =
  result = """
<html>
<head>
  <link rel="StyleSheet" href="/style.css" type="text/css" />
</head>
<body>
"""
  result &= base
  result &= "</body></html>"
  
proc match(request: Request): Future[ResponseData] {.async, gcsafe.} =
  block route:
    let decoded = request.pathInfo.decodeUrl()
    let requestSplit = decoded.splitFile()
   
    let filepath = (path / decoded).normalizedPath

    if requestSplit.ext == "" or requestSplit.ext in markdownExts:
      for ext in markdownExts:
        let np = filepath.changeFileExt(ext)
        if fileExists(np):
          resp markdown(readFile(np)).constHtml()
      if requestSplit.ext == "" and dirExists(filepath):
        var files: seq[string]
        if request.pathInfo != "/":
          files.add("..")
        for kind, item in walkDir(filepath):
          files.add item
        var links: string = &"<h1>(dir) {filepath}</h1><div>"
        for file in files:
          let (fdir, fname, fext) = file.splitFile()
          var format = &"{fname}{fext}"
          var link = &"{fname}{fext}"
          if dirExists(file):
            format = "(dir) " & format
            link &= "/"
          links &= &"<p><a href=\"{link}\">{format}</a></p>"
        links &= "</div>"
        resp links.constHtml()
    else:
      if fileExists(filepath):
        resp readFile(filepath), "binary"
      else:
        resp Http404, h1("Not found").constHtml()


proc main(port: int) =
  let settings = newSettings(port=port.Port)
  var jester = initJester(match, settings = settings)
  jester.serve()

proc displayHelp =
  echo """
Usage: suckwiki [-p:port] [/path/to/wiki/folder]
Alternatively set the $WIKIPATH env var
"""
  quit(1)

when isMainModule:
  if existsEnv("WIKIPATH"):
    path = getEnv("WIKIPATH")
  elif existsEnv("XDG_DATA_HOME"):
    path = getEnv("XDG_DATA_HOME") / "suckwiki"
  elif existsEnv("HOME"):
    path = getEnv("HOME") / ".suckwiki"

  var port = 8888

  var p = initOptParser()
  while true:
    p.next()
    case p.kind:
      of cmdEnd: break
      of cmdShortOption, cmdLongOption:
        if p.val == "":
          displayHelp()
        else:
          if p.key == "p":
            try:
              port = parseInt(p.val)
            except:
              displayHelp()
          else:
            displayHelp()
      else:
        if dirExists(p.key):
          path = p.key
        else:
          echo &"Specified path {path} is not a directory."
          quit(1)
  if not dirExists(path):
    echo "Unknown wiki location. Please set the env var WIKI."
    quit(1)
  echo "Serving wiki from " & path & " on port " & $port
    
  main(port)
