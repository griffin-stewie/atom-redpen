# redpen - Atom package

Validate your document using [RedPen](http://redpen.cc/).

![A screenshot of your spankin' package](http://i.gyazo.com/d67abf2d7bbb8d404d94a3d63f59dd39.gif)

## Installation

```
$ apm install redpen
```

## Usage

### Install `RedPen` CLI

Install `RedPen` CLI from [here](http://redpen.cc/docs/latest/index.html "QuickStart — RedPen 1.0-Beta documentation")

### Set Up Paths

This package needs set up some paths from Settings

- Path for RedPen CLI
    - `/usr/local/redpen/bin/redpen` is default
- Path for Configuration XML File
    - RedPen CLI needs configuration XML file for validation. you can set your configuration XML file. This package uses preinstalled japanese configuration XML file as default if empty.
- JAVA_HOME Path
    - RedPen CLI needs JAVA_HOME path.

### Run

1. open a text file as bellow
    - Markdown
    - Textile
    - Plain
2. Select the `RedPen: Validate` command from Command Pallette. You can also execute it by hitting `cmd-alt-o` on OS X.
3. You can see report pane at bottom.

You can use `Validate on save` option from Settings If you want to run validation each time a file is saved.
