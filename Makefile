.PHONY: help setup deploy teardown

help:
	@echo "Available commands:"
	@echo "  setup         - Start the local K8s cluster with Minikube. Accepts the following options:"
	@echo "    cpu         - Number of CPUs to allocate to Kubernetes (E.g.: setup cpu=4)"
	@echo "    memory      - Amount of RAM to allocate to Kubernetes (E.g.: setup memory=8g)"
	@echo "  deploy        - Deploy the integration setup: OpenProject, Nextcloud and Keycloak"
	@echo "  deploy-dev    - Deploy the integration setup in development mode with local OpenProject source code."
	@echo "                  LOCAL_SOURCE_PATH: Path to the local source code (E.g.: deploy-dev LOCAL_SOURCE_PATH=/path/to/openproject)"
	@echo "  teardown      - Delete the integration deployment from the K8s cluster"
	@echo "  teardown-all  - Delete the K8s cluster"

# minikube resources options
MK_OPTIONS := $(if $(cpu),--cpus=$(cpu))
MK_OPTIONS := $(if $(memory),$(if $(MK_OPTIONS),$(MK_OPTIONS) --memory=$(memory),--memory=$(memory)),$(MK_OPTIONS))

setup:
	minikube start $(MK_OPTIONS)
	minikube addons enable ingress

deploy:
	@helmfile sync

deploy-dev:
	@if [ -z "$(LOCAL_SOURCE_PATH)" ]; then echo "[ERROR] 'LOCAL_SOURCE_PATH' is not provided."; exit 1; fi
	@if [ ! -d "$(LOCAL_SOURCE_PATH)" ]; then echo "[ERROR] 'LOCAL_SOURCE_PATH' does not exist or is not a directory."; exit 1; fi
	@if [ -f tmp/mount.pid ]; then kill `cat tmp/mount.pid` || true; fi
	@minikube mount $(LOCAL_SOURCE_PATH):/localDir & echo $$! > tmp/mount.pid
	@helmfile sync -e dev

teardown:
	@./scripts/teardown

teardown-all:
	@./scripts/teardown --all
