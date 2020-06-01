#!/bin/bash
hugo -d ../marzelwidmer.github.io 
cd ../marzelwidmer.github.io   
git add .
git commit -m "Update blog"
git push