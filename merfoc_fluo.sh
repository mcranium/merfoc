#!/bin/bash
for d in ./*/
do
        cd "$d"
        shopt -s nullglob
        for i in *.[Jj][Pp][Gg] *.[Jj][Pp][Ee][Gg] *.[Pp][Nn][Gg] *.[Tt][Ii][Ff] *.[Tt][Ii][Ff][Ff]
        do
                convert $i -colorspace RGB \
                       -channel B \
                       -evaluate set 0 +channel \
                       -colorspace Gray \
                       redgreen_$i.tif 
        done
        align_image_stack redgreen*.tif -a aligned_ -m -i --use-given-order -c 20

        rm redgreen*

        enfuse aligned_* --hard-mask \
                --contrast-weight 1 \
                --exposure-weight 0 \
                --saturation-weight 0 \
                --contrast-window 7 \
                --contrast-edge-scale=0.3 \
                --contrast-min-curvature=-0.5% \
                -o ${PWD##*/}_merfoc_fluo.tif

        rm aligned*
        mv *_merfoc_fluo.tif ..
        cd ..
done


