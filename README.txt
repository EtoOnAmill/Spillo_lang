Welcome to SpilloLang!

This is my personal attempt at a dependently typed functional language with algebraic effects; but mostly it is my way to explore unusual features in programming languages and trying to tying them together in a cohesive and easy to use manner.


DEPENDENCIES
This repo is written in the D programming language, the compiler in my developement has been dmd built from source (commit hash be8668e9380d3cc07cffa183a77336ab09351f7f) with phobos (commit hash 9971927d535961da0e55f39e95b576bf70233191).
It uses plain gnu make for it's build system.


BUILDING
Have a working dmd compiler and make, the comands are the usual:

build everything
make all

remove build artifacts including the executable:
make clean


INSTALLING
For now it is too much a hassle to figure out how to do it properly so add the executable in your shell PATH with the syntax `/full/path/to/executable:PATH`
