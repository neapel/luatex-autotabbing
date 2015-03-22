NAME = autotabbing
FORMAT = lualatex

DTX = $(NAME).dtx
DOC = $(NAME).pdf
STY = $(NAME).sty
LUA = $(NAME).lua

TEXMFROOT = ./texmf
RUNDIR = $(TEXMFROOT)/tex/$(FORMAT)/$(NAME)
DOCDIR = $(TEXMFROOT)/doc/$(FORMAT)/$(NAME)
SRCDIR = $(TEXMFROOT)/source/$(FORMAT)/$(NAME)

RUNFILES = $(STY) $(LUA)
DOCFILES = $(DOC) README
SRCFILES = $(DTX) Makefile

ALLFILES = $(RUNFILES) $(DOCFILES) $(SRCFILES)

DISTDIR = $(NAME)
ZIP = $(NAME).zip

$(DOC) : $(DTX) $(STY) $(LUA)
	lualatex -synctex=1 $<

$(STY) $(LUA) : $(DTX)
	tex $<

.PHONY : install
install : $(ALLFILES)
	mkdir -p $(RUNDIR)
	cp $(RUNFILES) $(RUNDIR)
	mkdir -p $(DOCDIR)
	cp $(DOCFILES) $(DOCDIR)
	mkdir -p $(SRCDIR)
	cp $(SRCFILES) $(SRCDIR)

$(ZIP) : $(ALLFILES)
	-rm -rf $(DISTDIR)
	mkdir $(DISTDIR)
	cp $(ALLFILES) $(DISTDIR)
	zip -r -9 $@ $(DISTDIR)
