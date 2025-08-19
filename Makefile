.PHONY: help setup deploy teardown

help:
	@echo "Available commands:"
	@echo "  setup         - Start the local K8s cluster with Minikube"
	@echo "  deploy        - Deploy the integration setup: OpenProject, Nextcloud and Keycloak"
	@echo "  teardown      - Delete the integration deployment from the K8s cluster"
	@echo "  teardown-all  - Delete the K8s cluster"

setup:
	@minikube start
	@minikube addons enable ingress
	@echo "Installing cert manager..."
	@helm install \
		cert-manager cert-manager --repo https://charts.jetstack.io \
		--namespace cert-manager \
		--create-namespace \
		--set crds.enabled=true

deploy:
	@helmfile apply

teardown:
	@./scripts/teardown

teardown-all:
	@./scripts/teardown --all
