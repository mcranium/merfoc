#!/bin/bash
for d in ./*/
do
        cd "$d"

        images=$(find *.[Jj][Pp][Gg] *.[Jj][Pp][Ee][Gg] *.[Pp][Nn][Gg] *.[Tt][Ii][Ff] *.[Tt][Ii][Ff][Ff])

        focus-stack $images --output=${PWD##*/}_merfoc_fs.tif

        mv *_merfoc_fs.tif ..

        cd ..
done
