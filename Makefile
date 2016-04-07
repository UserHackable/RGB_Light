# # Put in your GitHub account details.
# 
# # Gerbv PCB image preview parameters - colours, plus resolution.
-include gerbv_colors.mk # load colors 

GERBER_IMAGE_RESOLUTION?=600
BACKGROUND_COLOR?=\#006600
HOLES_COLOR?=\#000000
SILKSCREEN_COLOR?=\#ffffff
PADS_COLOR?=\#FFDE4E
TOP_SOLDERMASK_COLOR?=\#009900
BOTTOM_SOLDERMASK_COLOR?=\#2D114A
GERBV_OPTIONS= --export=png --dpi=$(GERBER_IMAGE_RESOLUTION) --background=$(BACKGROUND_COLOR) --border=1

# # STUFF YOU WILL NEED:
# #  gerbv and eagle must be installed and must be in path.
# 
# # On Mac OSX we will create a link to the Eagle binary:
# # sudo ln -s /Applications/EAGLE/EAGLE.app/Contents/MacOS/EAGLE /usr/bin/eagle 

boards := $(wildcard *.brd)
zips := $(patsubst %.brd,%_gerber.zip,$(boards))
pngs := $(patsubst %.brd,%.png,$(boards))
dris := $(patsubst %.brd,%.dri,$(boards))
gpis := $(patsubst %.brd,%.gpi,$(boards))
back_pngs := $(patsubst %.brd,%_back.png,$(boards))
mds := $(patsubst %.brd,%.md,$(boards))

# .SILENT: all gerbers git github clean

# .PHONY: gerbers

.SECONDARY: $(pngs)

.INTERMEDIATE: $(dris) $(gpis)

.IGNORE: git

GERBER_DIR=gerbers

.PHONY: zips pngs md clean clean_gerbers clean_temps clean_pngs clean_zips clean_mds all

all: md zips git

zips: $(zips)

pngs: $(pngs) $(back_pngs)

md: $(mds) README.md

README.md: Intro.md $(mds)
	cat $+ > README.md 
	rm -f $(mds)

%.GTL: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< Top Pads Vias Dimension

%.GBL: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< Bottom Pads Vias Dimension

%.GTO: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< tPlace tNames tValues

%.GTP: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< tCream

%.GBO: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< bPlace bNames bValues

%.GTS: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< tStop

%.GBS: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< bStop

%.GML: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< Milling

%.TXT: %.brd
	eagle -X -d EXCELLON_24 -o $@ $< Drills Holes

%.OLN: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< Dimension

%_gerber.zip: %.GTL %.GBL %.GTO %.GTP %.GBO %.GTS %.GBS %.GML %.TXT %.png %_back.png
	zip $@ $^ $*.dri $*.gpi 
	rm -f $*.dri $*.gpi

%.png: %.TXT %.GTO %.GTS %.GTL
	gerbv $(GERBV_OPTIONS) --output=$@ \
        --f=$(HOLES_COLOR) $*.TXT \
        --f=$(SILKSCREEN_COLOR) $*.GTO \
        --f=$(PADS_COLOR) $*.GTS \
        --f=$(TOP_SOLDERMASK_COLOR) $*.GTL
	convert $@ -alpha set -fill none -draw 'matte 0,0 floodfill' \( +clone -alpha extract -negate -morphology EdgeIn Diamond -negate -transparent white \) -background none -flatten -trim +repage $@

%_back.png: %.TXT %.GBO %.GBS %.GBL
	gerbv $(GERBV_OPTIONS) --output=$@ \
        --f=$(HOLES_COLOR) $*.TXT \
        --f=$(SILKSCREEN_COLOR) $*.GBO \
        --f=$(PADS_COLOR) $*.GBS \
        --f=$(TOP_SOLDERMASK_COLOR) $*.GBL
	convert $@ -alpha set -fill none -draw 'matte 0,0 floodfill' -flop \( +clone -alpha extract -negate -morphology EdgeIn Diamond -negate -transparent white \) -background none -flatten -trim +repage $@

%.md: %.png %_back.png %.GTL
	echo "## $* \n\n" >  $@
	gerber_board_size $*.GTL >> $@
	echo "\n\n| Front | Back |\n| --- | --- |\n| ![Front]($*.png) | ![Back]($*_back.png) |\n\n" >>  $@

.gitignore:
	echo "\n*~\n.*.swp\n*.?#?\n.*.lck" > $@

.git:
	git init

git: .git .gitignore
	git add . --all
	git commit -am 'from Makefile'
	git push

Intro.md:
	touch Intro.md

clean_gerbers:
	rm -f *.G[TBM][LOPS] *.TXT *.dri *.gpi

clean_temps: 
	rm -f *.[bs]#?

clean_pngs:
	rm -f *.png

clean_zips:
	rm -f *.zip

clean_mds:
	rm -f $(mds) README.md

clean: clean_gerbers clean_temps clean_pngs clean_zips clean_mds

