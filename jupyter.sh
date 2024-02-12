init_jupyter()
{
	sudo pip3 install notebook bash_kernel jupyter
  python3 -m bash_kernel.install
}

jconv()
{
	jupyter nbconvert --to "$1" "$2"
}

jconv_html()
{
	jconv html "$1"
}

jconv_pdf()
{
	jconv pdf "$1"
}

jconv_webpdf()
{
	jconv webpdf "$1"
}

jconv_slides()
{
	jconv slides "$1"
}

jconv_markdown()
{
	jconv markdown "$1"
}

jconv_asciidoc()
{
	jconv asciidoc "$1"
}

jconv_rst()
{
	jconv rst "$1"
}

jconv_script()
{
	jconv script "$1"
}

export PATH=$PATH:$HOME/.local/bin
alias bjupyter="jupyter notebook --kernel=bash --notebook-dir $_DIR/notebooks"