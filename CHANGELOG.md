## 0.5.0 - Support LaTeX

- Added support LaTex
- Requires RedPen v1.5 or higher

## 0.4.0 - Add searching configuration XML

Added searching configuration XML feature. order is

1. `Path for Configuration XML File` on settings
1. in the same directory as the target text file
1. in the project root directory
1. directly under `REDPEN_HOME`
1. directly under `REDPEN_HOME/conf/`
1. bundled redpen-conf-ja.xml

Configuration XML File name shold be

- `redpen-conf.xml`
- `redpen-conf-{LOCALE}.xml`

You can set your `{LOCALE}` on settings.


## 0.3.6 - fix crash

- fix "Cannot read property 'getGrammar' of undefined" #6


## 0.3.5 - supports AsciiDoc

- Supports AsciiDoc
    - requires redpen cli version 1.3
- fix "Cannot read property 'close' of null" #4

## 0.3.4 - fix deprecated calls

- fix deprecated calls

## 0.3.3 - fix deprecated calls

- fix deprecated calls

## 0.3.2 - fix deprecated calls

- fix deprecated calls

## 0.3.1 - show error position offset RedPen CLI v1.1.2

- fix compatibly for RedPen CLI v1.1.2

## 0.3.0 - show error position offset RedPen CLI v1.1.1

- update atom-message-panel
- fix panel close
- show atom-message-panel whenever needs to show.
- hide panel when focus changed

## 0.2.0 - Change internal redpen-cli output format

- change internal redpen-cli output format, XML → JSON
- remove `xml2json` library
- add redpen-cli version check. now requires redpen-cli v1.0 or higher.
- remove context menu
- fix menu action

## 0.1.1 - Fixed installation from apm

- fixed atom version
- remove trash file

## 0.1.0 - First Release

- Every feature added
