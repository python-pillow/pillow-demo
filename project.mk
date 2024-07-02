PROJECT_NAME := pillow-demo
GIT_MESSAGE := "Prep for Austin Py"

edit:
	vi index.html

serve: 
	$(MAKE) reveal-serve

install:
	$(MAKE) pip-install npm-install

deploy:
	python demo.py
