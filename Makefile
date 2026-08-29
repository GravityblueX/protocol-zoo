.PHONY: validate fixtures capture real-app sctp remaining era2-fixtures era2-capture era2-network era2-ipv6 era2-rip era2-ppp era2-validate era2-static era3-validate capabilities experiment clean check
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
era2-capture:
	./scripts/era2-capture.sh
era2-network:
	./scripts/era2-network-capture.sh
era2-ipv6:
	./scripts/era2-ipv6-capture.sh
era2-rip:
	./scripts/era2-rip-capture.sh
era2-ppp:
	./scripts/era2-ppp-capture.sh
era2-validate:
	./scripts/era2-validate.sh
era2-static:
	./scripts/era2-static-results.sh
era3-validate:
	./scripts/era3-validate.sh
check: fixtures capabilities validate era2-fixtures era2-static era2-validate era3-validate
