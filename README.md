# linux-scripts

## Various scripts to automate tasks on Linux

+ **compile** *-A simple script I wrote that will automate compilation with
  subversion and makepkg. It uses 3 different customizable makepkg configs with
  various levels of optimizations so that if one fails it will retry
  compilation using a different config file. Will probably be rewritten soon*
  `compile <pkg name>` Required packages (Arch Linux): base-devel, subversion

kernel has been moved to it's own repository [custom-kernel-manager](https://www.github.com/cjmcguire88/custom-kernel-manager) as it's become a bit more than a script at this point.
