validate:
	az deployment group validate \
		-g $(RG) \
		-f template.bicep \
		-p @parameters.json

deploy:
	az deployment group create \
		-g $(RG) \
		-f template.bicep \
		-p @parameters.json \
		--mode Complete

clean:
	az resource delete --ids `az resource list -g $(RG) --query '[].id' -o tsv`
