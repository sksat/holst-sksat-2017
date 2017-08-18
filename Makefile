%.eps:%.svg
	inkscape -C -z --file=$< --export-eps=$@

default:
	latexmk holst.tex

run:
	latexmk -pvc holst.tex

clean:
	rm -f *.aux *.dvi *.fdb_latexmk *.fls *.log *.synctex.gz
