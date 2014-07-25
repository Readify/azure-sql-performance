AzureSqlPerformance PowerShell Module
=====================================
A small PowerShell module which allows you to easily time how long it takes to import a given *.bacpac file into an Azure SQL Database.

What does it do?
----------------
Glad you asked. The PowerShell module contains a command called ```Test-AzureSqlDatabaseImportPerformance``` which takes a range of arguments to control the creation of an Azure SQL Database in a specific region, with a specific name, username etc. As part of the script we automatically create a new server within the specified region set the service objective and trigger an import. The scrip then monitors the status of the import until it either completes or fails. It then prints out how long in minutes the import took to run.

What is the status of this script?
----------------------------------
This is just a quick tool that we whacked together just to get some indicative timings on import performance. It isn't production quality script, but you are more than welcome to submit pull requests. We may even update it ourselves should we find the need.

Dependencies
------------
Using this module requires that you have an [Azure subscription](http://azure.microsoft.com) and have downloaded and [installed the Azure PowerShell tools](http://azure.microsoft.com/en-us/documentation/articles/install-configure-powershell/). Once you've got that all set-up read through the warnings below and then onto usage.

Warnings
--------
Microsoft will generally charge you money for any resource that you use on Azure. Azure SQL Database instances are no exception. However you need to be aware that SQL Database usage is charged on a daily, not hourly basis and some of the higher end service tiers can be relatively expensive if you are just mucking around. Before doing any performance testing make sure you throughly read through [Azure SQL Database pricing details](http://azure.microsoft.com/en-us/pricing/details/sql-database/).

Specifically if you create and delete a database 10 times in a row you will pay for 10 x the daily rate for the database, NOT 1 x the daily rate. For this reason it is worth getting comfortable with using this comment on the _Basic_ service tier first since it will cost you less than 10c every time you run the script.

_You have been warned!_

Usage
-----
Here is the usage details for the module:
```PowerShell
Import-Module .\AzureSqlPerformance.psm1
Test-AzureSqlDatabaseImportPerformance `
    -DatabaseName "import-test" `
    -ServerAdminUsername "myadmin" `
    -ServerAdminPassword "some password" `
    -ServerLocationName "East US" `
    -DatabaseEdition "Standard" `
    -DatabaseServiceObjective "S1" `
    -StorageAccountName "mystorageaccount" `
    -StorageAccountKey "rllpxLO6X0Tnvs/A00RG3jfosfdsfFNvZVTM5sdfssdf5sfdfs/XHuzxMuwSosfddsfsOqYISUjpJUljPC8xSKYnStO86ix3AqA==" `
    -StorageAccountContainer "bacpacs" `
    -StorageAccountBlobName "mybackup.bacpac" `
    -MaximumSizeGB 10 `
    -Verbose
```

Everything there should be pretty obvious. The location provided is validated before the server is created, as is the service objective. You can use the ```Get-AzureSqlDatabaseServiceObjective``` command to see what service objectives are available to you. You can check the list of locations using the ```Get-AzureLocation``` command.
