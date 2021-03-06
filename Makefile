NAME = observable-apps

ARCHIVE_NAME = $(NAME)-$(shell date +%Y-%m-%d)

SLIDES = $(NAME)-slides.html
SLIDES_DIST = $(NAME)-slides-standalone.html
SLIDES_STYLESHEET = $(wildcard slides.css)
IMAGES = $(wildcard *.png *.jpg *.svg *.gif)
ASSETS = $(wildcard $(IMAGES) $(SLIDES_STYLESHEET))
DIST_README = dist-readme.txt

all: $(SLIDES)
zip: $(ARCHIVE_NAME).zip
dist: $(SLIDES_DIST) $(ASSETS) $(DIST_README)
	mkdir -p dist
	# download external references, e.g. slidy CSS and JS
	sed -nE 's?.*\b(href|src)="(https\?://[^"]+)".*?\2?p' $< | grep -v '/index\.' | xargs -Iquux sh -c 'test -f dist/`basename quux` || wget --directory-prefix dist quux'
	ls dist/*.gz | xargs --no-run-if-empty gunzip
	if [ -n "$(ASSETS)" ]; then cp $(ASSETS) dist; fi
	# modify external references to point to downloaded assets
	sed -E 's?\b(href|src)="(https\?://[^"]+/([^"]+))"?\1="\3"?; s?\b(href|src)="(.*)\.gz"?\1="\2"?' $< > dist/$<
	mv dist/$(SLIDES_DIST) dist/index.html
	cp $(DIST_README) dist/README.txt

open: $(SLIDES)
	google-chrome file://$(PWD)/$(SLIDES)

$(ARCHIVE_NAME).zip: dist
	cd $< && zip ../$@ *

$(SLIDES): $(NAME).otl
	vimoutliner-pandoc --outline-style=notes --output-format=slidy <$< >$@
	if [ -n "$(SLIDES_STYLESHEET)" ]; then sed -i 's|</head>|\n<link href="$(SLIDES_STYLESHEET)" type="text/css" rel="stylesheet" />\n</head>|' $@; fi

$(SLIDES_DIST): $(SLIDES) $(SLIDES_STYLESHEET) splice.sed
	sed -f splice.sed $< >$@

clean:
	rm -rf $(SLIDES) $(SLIDES_DIST) dist
