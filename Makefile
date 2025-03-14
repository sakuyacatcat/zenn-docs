TITLE := ""

.PHONY: install
install:
	pip install -r requirements.txt && pre-commit install && npm install

.PHONY: run
run:
	npm run preview

.PHONY: article
article:
	npm run article $(TITLE)

.PHONY: lint
lint:
	npm run lint

.PHONY: format
format:
	npm run lint:fix

.PHONY: before_commit
before_commit: lint
