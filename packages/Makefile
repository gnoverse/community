.PHONY: help
help:
	@echo "Available make commands:"
	@cat Makefile | grep '^[a-z][^:]*:' | cut -d: -f1 | sort | sed 's/^/  /'


########################################
# Environment variables
# You can overwrite any of the following by passing a different value on the
# command line, ie. `CGO_ENABLED=1 make test`.

# disable cgo by default. cgo requires some additional dependencies in some
# cases, and is not strictly required by any tm2 code.
CGO_ENABLED ?= 0
export CGO_ENABLED
# flags for `make fmt`. -w will write the result to the destination files.
GOFMT_FLAGS ?= -w
# flags for `make imports`.
GOIMPORTS_FLAGS ?= $(GOFMT_FLAGS)
# test suite flags.
GOTEST_FLAGS ?= -v -p 1 -timeout=30m

########################################
run_gno := go run github.com/gnolang/gno/gnovm/cmd/gno

.PHONY: test
test:
	$(run_gno) test -v ./...

.PHONY: test.fast
test.fast:
	$(run_gno) test -v -failfast -v  ./...

.PHONY: lint
lint:
	$(run_gno) lint -v ./...

.PHONY: test.sync
test.sync:
	$(run_gno) test -v --update-golden-tests ./...

.PHONY: fmt
GNOFMT_FLAGS ?= -w
fmt:
	$(run_gno) fmt $(GNOFMT_FLAGS) ./...

.PHONY: tidy
tidy:
	$(run_gno) mod tidy -v --recursive
