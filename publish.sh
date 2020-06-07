#!/bin/bash
hugo -d ../marzelwidmer.github.io 
cd ../marzelwidmer.github.io  || exit
git checkout master
git add .
git commit -m "Update blog"
git push