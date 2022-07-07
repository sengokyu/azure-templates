GROUP_NAME:=ex-wordpress
LOCATION:=japaneast

group:
	az group create -g $(GROUP_NAME) -l $(LOCATION)

storage:
	az deployment group create \
		--resource-group $(GROUP_NAME) \
		--template-file 01-storage.bicep

database:
	az deployment group create \
		--resource-group $(GROUP_NAME) \
		--template-file 02-database.bicep \
		--parameters mariaDbPassword=$(PASSWORD)

web:
	storageAccountName=$$(az storage account list -g $(GROUP_NAME) --query '[].name' -o tsv); \
	az deployment group create \
		--resource-group $(GROUP_NAME) \
		--template-file 03-web.bicep \
		--parameters storageAccountName=$${storageAccountName}

clean:
	az group delete -g $(GROUP_NAME) --yes
