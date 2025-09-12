.PHONY: help setup deploy teardown

help:
	@echo "Available commands:"
	@echo "  setup         - Start the local K8s cluster with Minikube. Accepts the following options:"
	@echo "    cpu         - Number of CPUs to allocate to Kubernetes (E.g.: setup cpu=4)"
	@echo "    memory      - Amount of RAM to allocate to Kubernetes (E.g.: setup memory=8g)"
	@echo "  deploy        - Deploy the integration setup: OpenProject, Nextcloud and Keycloak"
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

deploy-local:
	@helmfile sync -e local

teardown:
	@./scripts/teardown

teardown-all:
	@./scripts/teardown --all
