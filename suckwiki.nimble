# Package

version       = "0.1.0"
author        = "Productive2"
description   = "Serve a folder of markdown documents locally"
license       = "GPL-2.0"
srcDir        = "src"
bin           = @["suckwiki"]


# Dependencies

requires "nim >= 1.0.0"
requires "markdown >= 0.8.0"
requires "jester >= 0.5.0"

