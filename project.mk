PROJECT_NAME := pillow-demo

edit:
	vi index.html

serve: 
	$(MAKE) reveal-serve

install:
	$(MAKE) pip-install npm-install

deploy:
	python demo.py
