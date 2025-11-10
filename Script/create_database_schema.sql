/*
=============================================================
Create Database and Schemas
=============================================================
Create a new database named 'DataWarehouse'
If the database already exists, it is dropped and recreated.
Additionally, the script also creates 3 schema: 'bronze', 'silver' and 'gold'.

NOTE: running this script will drop the entire database 'DataWarehouse' if it exists
*/

USE master;
GO

-- Drop and recreate the 'DataWarehouse' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO

-- Create the 'DataWarehouse' database
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- Create Schemas
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
