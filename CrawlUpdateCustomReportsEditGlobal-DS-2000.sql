-- lets create our temp table that will
-- hold our district names
CREATE TABLE #tmpDatabases (
  ID int IDENTITY (1, 1) PRIMARY KEY,
  NAME nvarchar(100),
  SERVERNAME nvarchar(100),
  [READONLY] bit
);
  
-- fill it in with the dbNames
-- avoiding global and system related dbs
INSERT INTO #tmpDatabases (NAME, SERVERNAME, [READONLY])
  SELECT
    DatabaseName,
    ServerName,
    [ReadOnly]
  FROM DS_Admin..ADMIN_Districts
  WHERE (
  DatabaseName NOT LIKE '%demo%'
  AND DatabaseName NOT LIKE '%temp%'
  AND DatabaseName NOT LIKE '%ext%'
  AND DatabaseName NOT LIKE '%staff%'
  AND DatabaseName NOT LIKE '%test%'
  AND DatabaseName NOT LIKE '%dev%'
  AND DatabaseName LIKE 'ds%'
  )
  AND ServerName LIKE '%' + @@SERVERNAME + '%'
  AND ISNULL([ReadOnly], 0) = 0
  
------------------------------------------------------------------------------------------------------------------------------------------
-- begin the check process
-- Declare SQLString as nvarchar(4000)
-- for instances where we are connecting to a SQL Server 2000 instance,
-- we cannot use varchar(max) because this is a feature
-- introduced on SQL Server 2005
DECLARE @SQLString AS nvarchar(4000)
DECLARE @DS AS nvarchar(100)
DECLARE @DistrictCount int
DECLARE @Looper int
  
SET @Looper = 1
  
-- get the number of sites
SELECT
  @DistrictCount = COUNT(*)
FROM #tmpDatabases;
  
   
-- crawl process
-- this part is where SQL is made to crawl the
-- different sites base on the entries
-- of #tmpDatabases
WHILE (@looper <= @DistrictCount)
BEGIN
  -- only do the check if tblSecurityGroup exist
  -- could be redundant since we are already
  -- screening out non district replated dbs
  IF (
    EXISTS (SELECT
      *
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_NAME = 'tblSecurityGroup')
    )
  BEGIN
    -- process each district
    SELECT
      @DS = NAME
    FROM #tmpDatabases
    WHERE ID = @looper
  
    SET @SQLString = 'UPDATE '+ @DS + '..tblSecurityGroup
                        set
                        CustomReportsEditGlobal = 1
                    WHERE
                        SecurityGroupNum IN (2000)';
  
    -- run our string as an SQL
    EXECUTE sp_executesql @SQLString
  END
  
  
  SET @looper = @looper + 1
END
  
-- housekeeping
DROP TABLE #tmpDatabases