# An Introduction to focus merging ("stacking") using command line tools

## Why the command line?
There are many programs available to perform the task of merging multiple images into a single image with everything in focus. Some of the most widely used programs are proprietary (e.g. Helicon Focus or Zerene Stacker). There are also many programs that are free/free and open that can do the same task in a similar quality as the proprietary programs. Probably the most widely used free and open focus merging program is [CombineZP](https://www.chip.de/downloads/CombineZP_27754625.html) (formerly CombineZ5 and CombineZM), which was the program that I used most often in the past years, because it is free and open and it produces high quality results. But what if you have to merge a lot of stacks and you don't want to spend an afternoon clicking through menus and waiting for the program to finish each job? A good solution to this is to use focus mergin programs in a batch mode. CombineZP for example comes with a companion program (CZBatch), that does exactly that. But CombineZP has its glitches and a lot of windows tend to pop up even if you use it in batch mode (practically making your computer unusable until the program finishes). Still, CombineZP is easy to use, consistently produces high quality results and, though designed for Windows, it can run on UNIX systems like GNU/Linux with the help of [WINE](https://www.winehq.org/) and derivative programs like [Winebotteler](https://winebottler.kronenberg.org/). This way for many people CombineZP will continue to be the best solution the open source realm.

But what if want to speed up your workflow by using a powerful server instead of your laptop or perform actions that are not included in your focus merging program without exporting and importing files by hand? What if you want to focus merge images automatically as soon as your digital microscope finished taking the pictures? Or what if you simply want your focus merging to be done quietly in a terminal window while you are doing something else? If you are able to move your focus merging workflow to the command line all of this (and a lot more) is possible.

## What programs to use?
Even though CombineZP seems to have command line functionality, I avoided using it so far because it is a Windows program and the errors which I can run into might be really hard to fix on on my Linux systems.
For the alignment of the images, which is **extremely** important if you are not using high precision equipment, I chose the program [Hugin](http://hugin.sourceforge.net/). Hugin has a graphical user interface (GUI), but it can as well be used from the command line. For the alignment we only need the function `align_image_stack`. The focus merging itself can be performed by [enfuse](http://enblend.sourceforge.net/).
For one of the example workflows below I also used `convert` from the program [Image Magick](https://imagemagick.org/index.php), which in general is a great tool to convert and manipulate images fast and on the command line.
All of these programs are available via most package managers on Linux and can be installed with a single line in the terminal:

```bash
sudo apt install hugin enfuse imagemagick imagemagick-doc
```
(on Debian/Ubuntu)

Instructions on how to install these programs on MacOS are available on the respective websites linked above.

## The alignment
The program align_image_stack from Hugin takes the names of the images which have to be aligned as the first argument (arguments come after the name of the program and are separated by spaces). To export the aligned images as image files we need to put the option `-a` followed optionally by the prefix (the name that the aligned images should have). The argument `-m` tells the program to resize the images. This is needed when the magnification is slightly different between the images (happens in many optical setups). The argument `-i` tells the program to optimize the image center shift. `--use-given-order` tells the program to not use the darkest image as the first in the stack. This seems to be a weird default but hugin is often used to do align for HDR (high dynamic range) images, where this makes sense. With the argument `-c` you can specify the number of reference points used during the alignment. The default value was too small for my large DSLR camera images so I increased the number to 20.

```bash
align_image_stack image_1 image_2 image_3 \
                        -a aligned_ -m -i \
                        --use-given-order \
                        -c 20
```

```bash
align_image_stack IMG* \
                -a aligned_ \
                -m -i \
                --use-given-order \
                -c 20
```

This command takes all images beginning with the letters `IMG` (case sensitive!) which are in the current directory (folder) as input of the program. The backslash sign only acts as a line break and allows to write oneliners on multiple lines to increase he readability.

Depending on your hardware it might make sense to use the GPU wit the argument `-gpu` to speed up the alignment process (haven't tried it yet).

## The focus merging
The program we use – enfuse – can not only merge focus stacks but also stacks of imaes with different illumination (HDR). The default values of the program are not suitable for focus merging. Enfuse takes the names of the images which have to be aligned as the first argument. The options `--hard-mask` `--contrast-weight` `--exopsure-weight` and `--saturation-weight` have to be set as below for enfuse to be useful for focus merging. 

```bash
enfuse aligned_* --hard-mask \
                --contrast-weight 1 \
                --exposure-weight 0 \
                --saturation-weight 0 \
                --contrast-window 7 \
                --contrast-edge-scale=0.3 \
                --contrast-min-curvature=-0.5% \
                -o merfoc.tif
```
Takes all images beginning with `aligned_` as input and outputs (argument `-o`) a single image with the name `merfoc.tif`
The other arguments are optional and the values given here are based on my judgement of the results from my images. Different images may need different settings. The meaning of the settings can be researched in the [documentation of enfuse](http://enblend.sourceforge.net/enfuse.doc/enfuse_4.2.pdf), which is vast and really not easy to understand.

## Simple example workflow (`merfoc.sh`)
To not repeat this commands for each stack the commands can be combined into a shell script, which can act like a program on the command line. The script explained here can be found as downloadable files in this repository.
For this script to work properly, the image files of each stack must be in their own folders (and checked and for eventual 90 degree rotations!). The folders should be inside an ideally empty folder (text files etc. are unproblematic but images could get overwritten accidentally). What the script does is, it searches for folders and sequentially goes into them and performs the alignment followed by the focus merging. It leaves the original images as they are and saves the merged images in the parent directory (where the stack-folders are located). The name of the output image is defined by the names of the stack folders and the suffix specified in the script.

To start the script you have to give the file the permission to be executed as a program (right click on the script in your file manager and change the permissions or do so on the command line `chmod +x merfoc.sh`). You also need to know where the script is or link it to a place where your operating system searches for executables. Go into the directory where your folders with the stacks are and type on the commandline:

```bash
/path/to/merfoc.sh
```

## Reducing the glowing light around fluorescent fibers when photogaphing with UV light (`merfoc_fluo.sh`)
This script is not much different from the one above. The difference is that now the program convert is called prior to the alignment to eliminate the blue colour channel and desaturate the images. 

```bash
convert image_1 -colorspace RGB \
                       -channel B \
                       -evaluate set 0 +channel \
                       -colorspace Gray \
                       image_1_redgreen.tif 
```
To run this script give it the permission and in the correct directory type:

```bash
/path/to/merfoc_fluo.sh
```


