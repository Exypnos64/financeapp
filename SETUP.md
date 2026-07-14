# Finance App Setup

> All commands as written work from the root of this project.

### 1. Ensure you have .NET 10 installed

To be done in an administrator powershell terminal:

```powershell
Invoke-WebRequest -Uri "https://dot.net/v1/dotnet-install.ps1" -OutFile "./dotnet-install.ps1"
./dotnet-install.ps1 -Channel 10.0
```

### 2. Ensure you have Docker installed and running

```powershell
winget install Docker.DockerDesktop
```

Be sure to open Docker Desktop after it's installed.

### 3. Ensure you have sqlpackage installed

`dotnet tool install --global Microsoft.SqlPackage`

### 4. Build the dacpac

`dotnet build MSSQL\FinanceDb.sqlproj`

### 5. Create your environment password

Make a copy of `db.env.example` and change the password to your own. It needs to have at least 8 characters and 3 of the 4 following categories.:

- Uppercase letter
- Lowercase letter
- Number
- Special Character

### 6. Setup Docker

This is only to be run once. Afterward use `docker start financedb`; `start` can be changed out for `stop` and `restart`.

```powershell
docker run -d --name financedb -e "ACCEPT_EULA=Y" --env-file db.env -p 1433:1433 -v financedb-data:/var/opt/mssql mcr.microsoft.com/mssql/server:2022-CU14-ubuntu-22.04
```

### 7. Publish the package to the Docker server

```powershell
.\MSSQL\PublishSqlPackage.ps1
```

This [publishing script](MSSQL\PublishSqlPackage.ps1) idempotently publishes your script to the Docker server.

The first command in the script stores your password in an environment variable so it doesn't get stored as plaintext in your shell history. The second publishes it.

> If you are unable to run the script, you can copy and paste the commands manually or run the following to enable running powershell scripts on your system:  
`Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`

### 8. Open MSSQL

Connect to the server with the following settings:
    - Server name: localhost,1433
    - Authentication: SQL Server Authentication
    - Login: sa
    - Password: *your environment password*
    - Encryption: Mandatory
    - Trust server certificate: True

### 9. Verify everything is up and running

You can run the following selects to ensure that setup was successful. There should be data populating both of these tables from `MSSQL\Script.PostDeployment.sql`.

```sql
SELECT * FROM dbo.CategoryGroup;
SELECT * FROM dbo.Category;
```
