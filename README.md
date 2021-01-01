# An Introduction to merging focus stacks using command line tools

## Why the command line?
There are many programs available to perform the task of merging multiple images into a single image with everything in focus. Some of the most widely used programs are proprietary (e.g. Helicon Focus or Zerene Stacker). There are also many programs that are free/free and open that can do the same task in a similar quality as the proprietary programs. Probably the most widely used free and open focus merging program is [CombineZP](https://www.chip.de/downloads/CombineZP_27754625.html) (formerly CombineZ5 and CombineZM), which was the program that I used most often in the past years, because it is free and open and it produces high quality results. But what if you have to merge a lot of stacks and you don't want to spend an afternoon clicking through menus and waiting for the program to finish each job? A good solution to this is to use focus mergin programs in a batch mode. CombineZP for example comes with a companion program (CZBatch), that does exactly that. But CombineZP has its glitches and a lot of windows tend to pop up even if you use it in batch mode (practically making your computer unusable until the program finishes). Still, CombineZP is easy to use, consistently produces high quality results and, though designed for Windows, it can run on UNIX systems like GNU/Linux with the help of [WINE](https://www.winehq.org/) and derivative programs like [Winebotteler](https://winebottler.kronenberg.org/). This way for many people CombineZP will continue to be the best solution the open source realm.

But what if want to speed up your workflow by using a powerful server instead of your laptop or perform actions that are not included in your focus merging program without exporting and importing files by hand? What if you want to focus merge images automatically as soon as your digital microscope finished taking the pictures? Or what if you simply want your focus merging to be done quietly in a terminal window while you are doing something else? If you are able to move your focus merging workflow to the command line all of this (and a lot more) is possible. Also, if there are new methods for focus merging, in most cases they will be available as command line programs before (if ever) someone writes a graphical user interface (GUI) for them.

## What programs to use?
Even though CombineZP seems to have command line functionality, I avoided using it so far because it is a Windows program and the errors which I can run into might be really hard to fix on on my Linux systems. 


### Hugin and Enfuse
One way is to use `enfuse` from [Enfuse/Enblend](http://enblend.sourceforge.net/). However, `enfuse` can only perform the focus mergin process but not the image alignment. For the image alignment another program is needed. For this we can use `align_image_stack` from the software suite [Hugin](http://hugin.sourceforge.net/). Both programs are easily available on most Linux distributions via the inbuilt package managers and can also be installed on other UNIX systems such as MacOS (not tested personally).


```bash
# for Debian/Ubuntu (based) distributions:
sudo apt install hugin enfuse 
```
Instructions on how to install these programs on MacOS are available on the respective websites linked above.

#### The alignment
Hugin has a graphical user interface (GUI), but it can as well be used from the command line. For the alignment we only need the function `align_image_stack`. The program `align_image_stack` from Hugin takes the names of the images which have to be aligned as the first argument (arguments come after the name of the program and are separated by spaces). To export the aligned images as image files we need to put the option `-a` followed optionally by the prefix (the name that the aligned images should have). The argument `-m` tells the program to resize the images. This is needed when the magnification is slightly different between the images (happens in many optical setups). The argument `-i` tells the program to optimize the image center shift. `--use-given-order` tells the program to not use the darkest image as the first in the stack. This seems to be a weird default but hugin is often used to do align for HDR (high dynamic range) images, where this makes sense. With the argument `-c` you can specify the number of reference points used during the alignment. The default value was too small for my large DSLR camera images so I increased the number to 20.

```bash
align_image_stack image_1 image_2 image_3 \
                        -a aligned_ -m -i \
                        --use-given-order \
                        -c 20
```

Writing or pasting in names of files is of course very inefficient. The below command takes all images beginning with the letters `IMG` (case sensitive!) which are in the current directory (folder) as input of the program. The backslash sign only acts as a line break and allows to write oneliners on multiple lines to increase he readability.

```bash
align_image_stack IMG* \
                -a aligned_ \
                -m -i \
                --use-given-order \
                -c 20
```


Depending on your hardware it might make sense to use the GPU wit the argument `-gpu` to speed up the alignment process (haven't tried it yet).


#### The focus merging
The program `enfuse`  can not only merge focus stacks but also stacks of images with different illumination (HDR). The default values of the program are not suitable for focus merging. Enfuse takes the names of the images which have to be aligned as the first argument. The options `--hard-mask` `--contrast-weight` `--exopsure-weight` and `--saturation-weight` have to be set as below for enfuse to be useful for focus merging. 

```bash
enfuse aligned_* --hard-mask \
                --contrast-weight 1 \
                --exposure-weight 0 \
                --saturation-weight 0 \
                --contrast-window 7 \
                --contrast-edge-scale=0.3 \
                --contrast-min-curvature=-0.5% \
                -o merfoc_enf.tif
```
The above command takes all images beginning with `aligned_` as input and outputs (argument `-o`) a single image with the name `merfoc.tif`
The other arguments are optional and the values given here are based on my judgement of the results from my images. Different images may need different settings. The meaning of the settings can be researched in the [documentation of enfuse](http://enblend.sourceforge.net/enfuse.doc/enfuse_4.2.pdf), which is very vast and detailed.


### `focus-stack`
The program [focus-stack](https://github.com/PetteriAimonen/focus-stack) by Petteri Aimonen can do both, the alignment and the focus merging. Also, even with the default settings it produces very good results. And it is **fast**. However, the installation is a bit more complex because it not available through package managers and has to be built from the source code. It depends on [OpenCV](https://opencv.org/), which has to be installed beforehand. It uses an algorithm developed by [Forster et al. 2004](http://bigwww.epfl.ch/publications/forster0404.html), which is also built into an [ImageJ plugin](http://bigwww.epfl.ch/demo/edf/).

```bash
focus-stack image_1 image_2 image_3 --output=/}_merfoc_fs.tif
```


## Efficiently using the command line programs
To not repeat this commands for each stack the commands can be wrapped into a shell script, which can act like a program on the command line. For this scripts to work properly, the image files of each stack must be in their own folders (and checked and for eventual 90 degree rotations!). The folders should be inside an ideally empty folder (text files etc. are unproblematic but images could get overwritten accidentally). This way, preparing the files is the same as for CZBatch. All of the scripts have in common that they search for folders and sequentially go into them and perform the alignment followed by the focus merging. The original images remain as they are before running the scripts and the merged images and placed in the parent directory (where the stack-folders are located). The name of the output image is defined by the names of the stack folders and the suffix specified in the script.

### `focus-stack` inside a script (`merfoc_fs.sh`)

```bash
#!/bin/bash
# This line needs to be in all bash shell scripts to tell the computer what to do with it (use bash to execute it)

# use a for loop to repeat the process for all folders in that directory
for d in ./*/
do
        # go into each folder
        cd "$d"

        # find image files and store them inside a variable
        images=$(find *.[Jj][Pp][Gg] *.[Jj][Pp][Ee][Gg] *.[Pp][Nn][Gg] *.[Tt][Ii][Ff] *.[Tt][Ii][Ff][Ff])

        # use a command line program that does the alignment and the focus merging in one go
        # the program takes the image file variable as the input
        focus-stack $images --output=${PWD##*/}_merfoc_fs.tif
        # the output image has the name of the folder as a prefix

        # to store the resulting in focus images of all focus stacks in one place they are moved up one directory
        mv *_merfoc_fs.tif ..

        # go out of each folder
        cd ..
done
```

### Hugin and Enfuse inside a script (`merfoc_enf.sh`)

```bash
#!/bin/bash

# use a for loop to repeat the process for all folders in that directory
for d in ./*/
do
        # go into each folder
        cd "$d"

        # find image files and store them inside a variable
        images=$(find *.[Jj][Pp][Gg] *.[Jj][Pp][Ee][Gg] *.[Pp][Nn][Gg] *.[Tt][Ii][Ff] *.[Tt][Ii][Ff][Ff])

        # use a command line program that does the alignment
        # the program takes the image file variable as the input
        # the output images should be named in a way that they are easily searchable
        align_image_stack $images -a aligned_ -m -i --use-given-order -c 20

        # use a command line program that does the focus merging
        # using the asterisk the program searches for the aligned images as input images
        enfuse aligned_* --hard-mask \
                --contrast-weight 1 \
                --exposure-weight 0 \
                --saturation-weight 0 \
                --contrast-window 7 \
                --contrast-edge-scale=0.3 \
                --contrast-min-curvature=-0.5% \
                -o ${PWD##*/}_merfoc_enf.tif

        # after the focus merging the aligned images can be deleted
        rm aligned*

        # to store the resulting in focus images of all focus stacks in one place they are moved up one directory
        mv *_merfoc_enf.tif ..

        # go out of each folder
        cd ..
done
```

The script explained here can also be found as downloadable files in this repository. To start the script you have to give the file the permission to be executed as a program (right click on the script in your file manager and change the permissions or do so on the command line `chmod +x merfoc.sh`). You also need to know where the script is or link it to a place where your operating system searches for executables. Go into the directory where your folders with the stacks are and type on the commandline:

```bash
/path/to/merfoc.sh
```

## Practical example: Reducing artefacts around fluorescent fibers when photographing with UV light (`merfoc_fluo.sh`)
When merging focus stacks of images from UV light photography there are often artefacts around dust fibers. Some dust fibers strongly glow in blue colour when exposed to UV light. When a focus stack is merged this can result in artefects which are much larger than the fiber itself. By removing the blue colour channel before the focus merging, the artfacts can be minimized. The `convert` function of the software suite [Image Magick](https://imagemagick.org/index.php) can do that when given the specific arguments. 

```bash
convert image_1 -colorspace RGB \
                       -channel B \
                       -evaluate set 0 +channel \
                       -colorspace Gray \
                       image_1_redgreen.tif 
```

Image Magick is in general a great tool to convert and manipulate images fast and on the command line that everyone should have on their system. This additional step can of course also be put into a shell script to be conveniently usable when handling a large number of stacks.

```bash
#!/bin/bash

# use a for loop to repeat the process for all folders in that directory
for d in ./*/
do
        # go into each folder
        cd "$d"


        # repeat the image manipulation (removing blue channel and desaturation) for all image files in the folder
        # give the output images an easily findable name
        shopt -s nullglob
        for i in *.[Jj][Pp][Gg] *.[Jj][Pp][Ee][Gg] *.[Pp][Nn][Gg] *.[Tt][Ii][Ff] *.[Tt][Ii][Ff][Ff]
        do
                convert $i -colorspace RGB \
                       -channel B \
                       -evaluate set 0 +channel \
                       -colorspace Gray \
                       redgreen_$i.tif 
        done

        # perform the alignment on the manipulated images
        align_image_stack redgreen*.tif -a aligned_ -m -i --use-given-order -c 20


        # remove the not aligned manipulated images
        rm redgreen*

        # perform the focus merging
        enfuse aligned_* --hard-mask \
                --contrast-weight 1 \
                --exposure-weight 0 \
                --saturation-weight 0 \
                --contrast-window 7 \
                --contrast-edge-scale=0.3 \
                --contrast-min-curvature=-0.5% \
                -o ${PWD##*/}_merfoc_fluo.tif

        # remove the aligned manipulated images
        rm aligned*

        # move the resulting in focus image up one directory
        mv *_merfoc_fluo.tif ..

        # go out of each folder
        cd ..
done
```
