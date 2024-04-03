PROJECT_NAME := pillow-demo

edit:
	# vi demo.py
	vi index.html

serve: 
	$(MAKE) reveal-serve

install:
	$(MAKE) pip-install npm-install

deploy:
	python demo.py
