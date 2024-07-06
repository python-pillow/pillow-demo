PROJECT_NAME := pillow-demo
GIT_MESSAGE := "Prep for Austin Py"

edit:
	vi index.html
	# vi demo.py

serve: 
	$(MAKE) reveal-serve

install:
	$(MAKE) pip-install npm-install

deploy:
	python demo.py

logo:
	python logo.py

logo-fancy:
	python logo_fancy.py

show:
	python show.py

fancy: logo-fancy
