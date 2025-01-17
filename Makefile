ROOT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
TOOLS_DIR := .tools

DB=tenant_api
DEV_DB=${DB}_dev
DEV_URI="postgresql://root@crdb:26257/${DEV_DB}?sslmode=disable"

# Determine OS and ARCH for some tool versions.
OS := linux
ARCH := amd64

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
	OS = darwin
endif

UNAME_P := $(shell uname -p)
ifneq ($(filter arm%,$(UNAME_P)),)
	ARCH = arm64
endif

# Tool Versions
COCKROACH_VERSION = v22.2.8

OS_VERSION = $(OS)
ifeq ($(OS),darwin)
OS_VERSION = darwin-10.9
ifeq ($(ARCH),arm64)
OS_VERSION = darwin-11.0
endif
endif

COCKROACH_VERSION_FILE = cockroach-$(COCKROACH_VERSION).$(OS_VERSION)-$(ARCH)
COCKROACH_RELEASE_URL = https://binaries.cockroachdb.com/$(COCKROACH_VERSION_FILE).tgz

GCI_REPO = github.com/daixiang0/gci
GCI_VERSION = v0.10.1

GOLANGCI_LINT_REPO = github.com/golangci/golangci-lint
GOLANGCI_LINT_VERSION = v1.51.2

SQLBOILER_REPO = github.com/volatiletech/sqlboiler/v4
SQLBOILER_VERSION = v4.14.2

SQLBOILER_CRDB_REPO = github.com/infratographer/sqlboiler-crdb/v4
SQLBOILER_CRDB_VERSION = latest

# go files to be checked
GO_FILES=$(shell git ls-files '*.go')

# Targets

.PHONY: help
help: Makefile ## Print help.
	@grep -h "##" $(MAKEFILE_LIST) | grep -v grep | sed -e 's/:.*##/#/' | column -c 2 -t -s#

.PHONY: all
all: lint test  ## Lints and tests.

.PHONY: ci
ci: | dev-database golint test coverage  ## Setup dev database and run tests.

.PHONY: dev-database
dev-database: | vendor $(TOOLS_DIR)/cockroach  ## Initializes dev database "${DEV_DB}"
	@$(TOOLS_DIR)/cockroach sql -e "drop database if exists ${DEV_DB}"
	@$(TOOLS_DIR)/cockroach sql -e "create database ${DEV_DB}"
	@TENANTAPI_CRDB_URI="${DEV_URI}" go run main.go migrate up

.PHONY: models sqlboiler-models
models: | dev-database sqlboiler-models  ## Regenerate models.

sqlboiler-models: | $(TOOLS_DIR)/sqlboiler $(TOOLS_DIR)/sqlboiler-crdb
	@echo -- Generating models...
	@PATH="$(ROOT_DIR)/$(TOOLS_DIR):$$PATH" \
		$(TOOLS_DIR)/sqlboiler crdb \
			--add-soft-deletes \
			--config sqlboiler.toml \
			--wipe \
			--no-tests
	@go mod tidy

.PHONY: test
test: | models unit-test  ## Rebuild models and run unit tests.

.PHONY: unit-test
unit-test: | $(TOOLS_DIR)/cockroach  ## Runs unit tests.
	@echo Running unit tests...
	@PATH="$(ROOT_DIR)/$(TOOLS_DIR):$$PATH" \
		go test -timeout 30s -cover -short ./...

.PHONY: coverage
coverage: | $(TOOLS_DIR)/cockroach  ## Generates a test coverage report.
	@echo Generating coverage report...
	@PATH="$(ROOT_DIR)/$(TOOLS_DIR):$$PATH" \
		go test -timeout 30s ./... -coverprofile=coverage.out -covermode=atomic
	@PATH="$(ROOT_DIR)/$(TOOLS_DIR):$$PATH" \
		go tool cover -func=coverage.out
	@PATH="$(ROOT_DIR)/$(TOOLS_DIR):$$PATH" \
		go tool cover -html=coverage.out

.PHONY: lint
lint: golint gci-diff  ## Runs all lint checks.

golint: | vendor $(TOOLS_DIR)/golangci-lint  ## Runs Go lint checks.
	@echo Linting Go files...
	@$(TOOLS_DIR)/golangci-lint run

vendor:  ## Downloads and tidies go modules.
	@go mod download
	@go mod tidy

.PHONY: gci-diff gci-write gci
gci-diff: $(GO_FILES) | $(TOOLS_DIR)/gci  ## Outputs improper go import ordering.
	@results=`$(TOOLS_DIR)/gci diff -s standard -s default -s 'prefix(github.com/infratographer)' $^` \
		&& echo "$$results" \
		&& [ -n "$$results" ] \
			&& [ "$(IGNORE_DIFF_ERROR)" != "true" ] \
			&& echo "Run make gci" \
			&& exit 1 || true

gci-write: $(GO_FILES) | $(TOOLS_DIR)/gci  ## Checks and updates all go files for proper import ordering.
	@$(TOOLS_DIR)/gci write -s standard -s default -s 'prefix(github.com/infratographer)' $^

gci: IGNORE_DIFF_ERROR=true
gci: | gci-diff gci-write  ## Outputs and corrects all improper go import ordering.

# Tools setup
$(TOOLS_DIR):
	mkdir -p $(TOOLS_DIR)

$(TOOLS_DIR)/cockroach: | $(TOOLS_DIR)
	@echo "Downloading cockroach: $(COCKROACH_RELEASE_URL)"
	@curl --silent --fail "$(COCKROACH_RELEASE_URL)" \
		| tar -xz --strip-components 1 -C $(TOOLS_DIR) $(COCKROACH_VERSION_FILE)/cockroach

	$@ version

$(TOOLS_DIR)/gci: | $(TOOLS_DIR)
	@echo "Installing $(GCI_REPO)@$(GCI_VERSION)"
	@GOBIN=$(ROOT_DIR)/$(TOOLS_DIR) go install $(GCI_REPO)@$(GCI_VERSION)
	$@ --version

$(TOOLS_DIR)/golangci-lint: | $(TOOLS_DIR)
	@echo "Installing $(GOLANGCI_LINT_REPO)/cmd/golangci-lint@$(GOLANGCI_LINT_VERSION)"
	@GOBIN=$(ROOT_DIR)/$(TOOLS_DIR) go install $(GOLANGCI_LINT_REPO)/cmd/golangci-lint@$(GOLANGCI_LINT_VERSION)
	$@ version
	$@ linters

$(TOOLS_DIR)/sqlboiler: | $(TOOLS_DIR)
	@echo "Installing $(SQLBOILER_REPO)@$(SQLBOILER_VERSION)"
	@GOBIN=$(ROOT_DIR)/$(TOOLS_DIR) go install $(SQLBOILER_REPO)@$(SQLBOILER_VERSION)
	$@ --version

$(TOOLS_DIR)/sqlboiler-crdb: | $(TOOLS_DIR)
	@echo "Installing $(SQLBOILER_CRDB_REPO)@$(SQLBOILER_CRDB_VERSION)"
	@GOBIN=$(ROOT_DIR)/$(TOOLS_DIR) go install $(SQLBOILER_CRDB_REPO)@$(SQLBOILER_CRDB_VERSION)
	$@ version
