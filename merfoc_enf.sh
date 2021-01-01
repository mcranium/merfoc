#!/bin/bash
for d in ./*/
do
        cd "$d"
        images=$(find *.[Jj][Pp][Gg] *.[Jj][Pp][Ee][Gg] *.[Pp][Nn][Gg] *.[Tt][Ii][Ff] *.[Tt][Ii][Ff][Ff])
        align_image_stack $images -a aligned_ -m -i --use-given-order -c 20

        enfuse aligned_* --hard-mask \
                --contrast-weight 1 \
                --exposure-weight 0 \
                --saturation-weight 0 \
                --contrast-window 7 \
                --contrast-edge-scale=0.3 \
                --contrast-min-curvature=-0.5% \
                -o ${PWD##*/}_merfoc.tif

        rm aligned*
        mv *_merfoc.tif ..
        cd ..
done


