%.eps:%.svg
	inkscape -C -z --file=$< --export-eps=$@

default:
	latexmk holst-sksat.tex

run:
	latexmk -pvc holst-sksat.tex

clean:
	rm -f *.aux *.dvi *.fdb_latexmk *.fls *.log *.synctex.gz
