# WordPress on Azure Container Instance

## Included resources

- Storage Account
  - File share
- Virtual Network (include 2 subnets)
- Azure Database for MariaDB
- Azure Container Group
- Public IP
- Application Gateway

## How to deploy

```console
make group
make storage
make database PASSWORD=your-database-password
make web
```
