%.eps:%.svg
	inkscape -C -z --file=$< --export-eps=$@

