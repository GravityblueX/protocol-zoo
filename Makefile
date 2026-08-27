.PHONY: validate fixtures capture clean
validate:
	./scripts/validate-repo.sh
fixtures:
	./scripts/make-fixtures.sh
capture:
	sudo ./scripts/dummy-capture.sh
clean:
	sudo ./scripts/lab-netns.sh teardown
