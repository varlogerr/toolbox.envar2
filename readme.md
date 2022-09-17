# <a id="top"></a>Envar

A set of tools to load environments from files.

* [Quick demo](#quick-demo)
* [Installation](#installation)
* [Usage](#usage)
* [Extras](#extras)
* [More configurations](#more-configurations)
* [Thoughts / TODOs](#thoughts--todos)
* [Development](#development)

## Quick demo

```sh
# perform initial setup
envar init
# generate environment files
envar gen ./env{1..2}.sh ./envdir{1..2}/env{1..2}.sh "${ENVAR_SPACE_PATH}/space1.sh"
# edit files
vim ./env{1..2}.sh ./envdir{1..2}/env{1..2}.sh "${ENVAR_SPACE_PATH}/space1.sh"
# desk-source environment files from a directory
envar . ./envdir1/
# desk-source file
envar . ./env1.sh
# same deskless
envar . -d ./envdir2/
envar . -d ./env2.sh
# list desks stack and all loaded files
envar stack
envar files
# load a space
envar space space1.sh
# leave last desk
exit # or just CTRL+d on the keyboard
# quit all desks
envar halt
# probably you wander what you just did...
envar -h
envar . -h
# and more `-h`
```

[To top]

## Installation

```sh
# download the tool
sudo git clone https://github.com/varlogerr/toolbox.envar2.git /opt/varlog/envar
# source to .bashrc file
echo ". /opt/varlog/envar/source.bash" >> ~/.bashrc
# load the changes
. ~/.bashrc
```

[To top]

## Usage

```sh
# view help
envar -h
# view actions helps
envar ACTION -h
```

`envar` is an alias function for a set of `envar_*` functions. They can be used by their own:

```sh
# equivalient of `envar source [ARGUMENTS]`
envar_source [ARGUMENTS]
# equivalient of `envar stack [ARGUMENTS]`
envar_stack [ARGUMENTS]
# ...
```

[To top]

## Extras

With the default sourcing of `source.bash` file 2 things happen:

1. `envar` alias function is loaded
1. `/etc/envar/init.d` and `~/.envar/init.d` directories are sourced if they exist

To disable this extras pass `--no-initd` to the source file to disable sourcing of `init.d` directories and `--no-alias` to disable `envar` alias function.

```sh
# File: ~/.bashrc
# ...
. /opt/varlog/envar/source.bash --no-alias --no-initd
# ...
```

Same can be achived with boolean `ENVAR_INITD_ENABLED` and `ENVAR_ALIAS_ENABLED` variables (both default to `true`):

```sh
# File: ~/.bashrc
# ...
ENVAR_INITD_ENABLED=false
ENVAR_ALIAS_ENABLED=false
. /opt/varlog/envar/source.bash
# ...
```

[To top]

## More configurations

* `ENVAR_INITD_PATH`, `--initd-path` (defaults to `~/.envar/init.d`) changes user init.d directory location
* `ENVAR_SPACE_PATH`, `--space-path` (defaults to `~/.envar/spaces`) changes spaces directory
* `ENVAR_INFO_LEVEL` (`none`, `major`, `minor`) info logging level, defaults to `major`


```sh
# File: ~/.bashrc
# ...
# Conigure with variables
ENVAR_INITD_PATH="${HOME}/.my-envar-initd-directory"
ENVAR_SPACE_PATH="${HOME}/.my-envar-space-directory"
. /opt/varlog/envar/source.bash
# ...
```

```sh
# File: ~/.bashrc
# ...
# Conigure with options
. /opt/varlog/envar/source.bash \
  --initd-path ~/.my-envar-initd-directory \
  --space-path ~/.my-envar-space-directory
# ...
```

[To top]

## Thoughts / TODOs

* add support for the closest directory in the path `.envar.d/spaces`

[To top]

## Development

Developers only stuff:

* `_envar_demo - `generate a demo set of env files
* `$_ENVAR_VAR - `state keeper
* `_envar_var - `prints `${_ENVAR_VAR}`

[To top]

[To top]: #top
