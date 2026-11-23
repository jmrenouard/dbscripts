IMAGE_NAME ?= dbscripts-script-tests:latest
REPO_ROOT := $(abspath $(CURDIR)/../..)
SCRIPT ?=

ifeq ($(OS),Windows_NT)
export MSYS_NO_PATHCONV := 1
export MSYS2_ARG_CONV_EXCL := *
MOUNT_ROOT := $(shell python -c "import pathlib, shutil; p=pathlib.Path(r'$(REPO_ROOT)').resolve(); d=shutil.which('docker') or ''; print('/mnt/'+p.drive[0].lower()+p.as_posix()[2:] if d.lower().endswith(('.cmd','.bat')) and p.drive else p.as_posix())")
else
MOUNT_ROOT := $(REPO_ROOT)
endif

.PHONY: build test test-one clean

build:
	docker build -t $(IMAGE_NAME) $(CURDIR)

test:
	docker run --rm -v "$(MOUNT_ROOT):/workspace:ro" $(IMAGE_NAME) bash /workspace/docker/script_tests/run_all_script_tests.sh

test-one:
	docker run --rm -v "$(MOUNT_ROOT):/workspace:ro" $(IMAGE_NAME) bash /workspace/docker/script_tests/run_all_script_tests.sh --require-filter "$(SCRIPT)"

clean:
	-docker image rm -f $(IMAGE_NAME)
