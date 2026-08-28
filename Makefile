.PHONY: validate fixtures capture capabilities experiment clean
validate:
	./scripts/experiment.sh validate
fixtures:
	./scripts/experiment.sh fixtures
capture:
	./scripts/experiment.sh capture
capabilities:
	./scripts/experiment.sh capabilities
experiment:
	@./scripts/experiment.sh
clean:
	./scripts/experiment.sh clean
