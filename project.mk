PROJECT_NAME := pillow-demo
GIT_MESSAGE := "Update demo"

edit:
	vi index.html
	# vi demo.py

serve: 
	$(MAKE) reveal-serve

install:
	$(MAKE) pip-install npm-install

deploy:
	python src/demo.py

logo:
	python src/logo.py

logo-fancy:
	python src/logo_fancy.py

fancy: logo-fancy

mode:
	python src/concepts/mode.py

size:
	python src/concepts/size.py

info:
	python src/concepts/info.py
