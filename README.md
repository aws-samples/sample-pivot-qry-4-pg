# Transition a pivot query that includes dynamic columns from SQL Server to PostgreSQL
This repository contains sample C#.Net code for using in the blog post - Transition a pivot query that includes dynamic columns from SQL Server to PostgreSQL.

The connection info need to be saved as a hard coded secret (sample-apg-conn) in AWS Secrets Manager.
1. host (Aurora PostgreSQL Cluster Endpoint)
2. dbname
3. port
4. username
5. password

# DDL and sample data for SQL Server
Sample-sql-server-data.sql

# DDL and sample data for Postgres
Sample-pg-data.sql

# Sample .NET project file
Sample-pivot-qry-4-pg.csproj

# Sample .NET code to call a Postgres stored function
Program.cs

# .NET deployment command
```
dotnet new console -n Sample-pivot-qry-4-pg

cd Sample-pivot-qry-4-pg

dotnet add package Npgsql

dotnet add package Newtonsoft.Json

dotnet add package AWSSDK.SecretsManager

dotnet add package AWSSDK.SecretsManager.Caching --version 1.0.6
```
Use Program.cs in this repo to replace the one created by dotnet command then run the following command
```
dotnet run
```

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.
