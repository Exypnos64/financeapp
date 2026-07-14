$pw = (Get-Content db.env | Where-Object { $_ -match '^MSSQL_SA_PASSWORD=' }) -replace '^MSSQL_SA_PASSWORD=', ''
sqlpackage /Action:Publish /SourceFile:"MSSQL\bin\Debug\FinanceDb.dacpac" /TargetServerName:"localhost,1433" /TargetDatabaseName:"FinanceDb" /TargetUser:"sa" /TargetPassword:$pw /TargetTrustServerCertificate:True
