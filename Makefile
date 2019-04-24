PACKAGE=$(shell awk '/^Package: / { print $$2 }' DESCRIPTION)
VERSION=$(shell awk '/^Version: / { print $$2 }' DESCRIPTION)
TARBALL=$(PACKAGE)_$(VERSION).tar.gz

all: check

build:
	R --vanilla CMD build .

check: build
	R --vanilla CMD check "$(TARBALL)"

check-as-cran: build
	R --vanilla CMD check --as-cran "$(TARBALL)"

install: build
	R --vanilla CMD INSTALL --install-tests --html --example "$(TARBALL)"

rebuild-data: install
	Rscript data-raw/generate_data.R
	make install

gh-pages:
	rm -r docs
	sh /usr/share/doc/git/contrib/workdir/git-new-workdir . docs gh-pages
	echo 'pkgdown::build_site()' | R --vanilla
	( cd docs/ && git add -A . && git commit -m "Docs for $(shell git rev-parse --short HEAD)" )

# Release steps
#  Update DESCRIPTION & ChangeLog with new version
#  git commit -m "Release version "${VERSION} DESCRIPTION ChangeLog
#  git tag -am "Release version "${VERSION} v${VERSION}
#  Upload to CRAN
#  git push && git push --tags

.PHONY: all install build check check-as-cran rebuild-data gh-pages
