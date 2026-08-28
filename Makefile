.PHONY: validate fixtures capture real-app sctp capabilities experiment clean
validate:
	./scripts/experiment.sh validate
fixtures:
	./scripts/experiment.sh fixtures
capture:
	./scripts/experiment.sh capture
real-app:
	./scripts/experiment.sh real-app
sctp:
	./scripts/experiment.sh sctp
capabilities:
	./scripts/experiment.sh capabilities
experiment:
	@./scripts/experiment.sh
clean:
	./scripts/experiment.sh clean
