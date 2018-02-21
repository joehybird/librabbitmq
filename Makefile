# Building
RABBIT_DIR=rabbitmq-c
CODEGEN_DIR=rabbitmq-codegen
RABBIT_TARGET=clib
RABBIT_DIST=rabbitmq-c-0.5.3

# Distribuition tools
PYTHON=python

all: build

add-submodules:
	-git submodule add https://github.com/ask/rabbitmq-c.git
	-git submodule add https://github.com/rabbitmq/rabbitmq-codegen

submodules:
	git submodule init
	git submodule update
	(cd $(RABBIT_DIR); rm -rf codegen; ln -sf ../$(CODEGEN_DIR) ./codegen)

rabbitmq-c: submodules
	(cd $(RABBIT_DIR); test -f configure || autoreconf -i)
	(cd $(RABBIT_DIR); test -f Makefile  || automake --add-missing)


rabbitmq-clean:
	-(cd $(RABBIT_DIR) && make clean)
	-(cd $(RABBIT_TARGET) && make clean)

rabbitmq-distclean:
	-(cd $(RABBIT_DIR) && make distclean)
	-(cd $(RABBIT_TARGET) && make distclean)

clean-build:
	-rm -rf build

build: clean-build dist
	python setup.py build

install: build
	python setup.py install

develop: build
	python setup.py develop

pyclean:
	-python setup.py clean
	-rm -rf build
	-rm -f _librabbitmq.so

clean: pyclean rabbitmq-clean

distclean: pyclean rabbitmq-distclean removepyc
	-rm -rf dist
	-rm -rf clib
	-rm -f erl_crash.dump

$(RABBIT_TARGET):
	(test -f config.h || cd $(RABBIT_DIR); ./configure --disable-tools --disable-docs)
	(cd $(RABBIT_DIR); make distdir)
	mv "$(RABBIT_DIR)/$(RABBIT_DIST)" "$(RABBIT_TARGET)"


dist: rabbitmq-c $(RABBIT_TARGET)


rebuild:
	python setup.py build
	python setup.py install


# Distro tools

flakecheck:
	flake8 librabbitmq setup.py

flakediag:
	-$(MAKE) flakecheck

flakepluscheck:
	flakeplus librabbitmq

flakeplusdiag:
	-$(MAKE) flakepluscheck

flakes: flakediag flakeplusdiag

test:
	nosetests -xv librabbitmq.tests

cov:
	nosetests -xv librabbitmq.tests --with-coverage --cover-html --cover-branch

removepyc:
	-find . -type f -a \( -name "*.pyc" -o -name "*$$py.class" \) -delete
	-find . -type d -name "__pycache__" -delete

gitclean:
	git clean -xdn

gitcleanforce:
	git clean -xdf

distcheck: flakecheck test gitclean
