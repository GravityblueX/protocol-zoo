.PHONY: validate fixtures capture real-app sctp remaining era2-fixtures era2-validate capabilities experiment clean check
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
remaining:
	./scripts/experiment.sh remaining
capabilities:
	./scripts/experiment.sh capabilities
experiment:
	@./scripts/experiment.sh
clean:
	./scripts/experiment.sh clean
era2-fixtures:
	./scripts/era2-fixtures.sh
era2-validate:
	./scripts/era2-validate.sh
check: fixtures capabilities validate era2-fixtures era2-validate
