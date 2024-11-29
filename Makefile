build-app:
	docker build . --target novel-next-app --tag novel-next-app:latest

build-docs:
	docker build . --target docs --tag docs:latest
