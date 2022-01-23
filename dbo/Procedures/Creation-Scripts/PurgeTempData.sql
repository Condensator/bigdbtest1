SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE   PROCEDURE [dbo].[PurgeTempData]
AS
SET NOCOUNT ON;
DECLARE @IsDBCdcEnabled BIT=0
DECLARE @IsReplicated BIT=0
DECLARE @TableName SYSNAME
DECLARE @IsTableTracked BIT=0
DECLARE @batchSize INT=1
DECLARE @IsReferenced BIT=0
DECLARE @PurgeFilter NVARCHAR(MAX)
DECLARE @ExistsInTempDb BIT=0
DECLARE @sql NVARCHAR(2000)
DECLARE @DbStatus sql_variant
Declare @databaseName NVARCHAR(500) = DB_Name()

CREATE TABLE #tableList
(
	TableName SysName,
	IsTrackedByCDC BIT,
	BatchSizeDetails INT,
	TableHasForeignRef INT,
	PurgeFilter nvarchar(4000),
	ExistsInTempDb BIT,
	ProcessingOrder INT
)

SELECT 	@IsDBCdcEnabled=is_cdc_enabled,	@IsReplicated=d.is_published FROM sys.databases d WHERE d.database_id=DB_ID();

SET @DbStatus = DATABASEPROPERTYEX(@databaseName, 'Updateability');

IF @DbStatus = 'READ_ONLY'
BEGIN
	INSERT INTO #tableList
	SELECT p.TableName,0, p.BatchSize, OBJECTPROPERTY(OBJECT_ID(p.TableName),'TableHasForeignRef'),p.PurgeFilter, p.ExistsInTempDb, p.ProcessingOrder
	FROM PurgeTableConfigs p WHERE p.ExistsInTempDb = 1 ORDER BY p.ProcessingOrder
END
ELSE
BEGIN
	INSERT INTO #tableList
 	SELECT t.[name],t.is_tracked_by_cdc, p.BatchSize, OBJECTPROPERTY(OBJECT_ID(t.NAME),'TableHasForeignRef'),p.PurgeFilter, p.ExistsInTempDb, p.ProcessingOrder
	FROM SYS.TABLES t JOIN PurgeTableConfigs p ON t.NAME=p.TableName AND p.ExistsInTempDb = 0 ORDER BY p.ProcessingOrder
	INSERT INTO #tableList
    SELECT p.TableName,0, p.BatchSize, OBJECTPROPERTY(OBJECT_ID(p.TableName),'TableHasForeignRef'),p.PurgeFilter, p.ExistsInTempDb, p.ProcessingOrder
	FROM PurgeTableConfigs p WHERE p.ExistsInTempDb = 1 ORDER BY p.ProcessingOrder
END

DECLARE CUR  CURSOR FORWARD_ONLY read_only  FOR 
	SELECT TableName,IsTrackedByCDC,BatchSizeDetails,TableHasForeignRef,PurgeFilter,ExistsInTempDb  FROM #tableList ORDER BY ProcessingOrder

OPEN CUR
FETCH NEXT FROM CUR INTO @TableName,@IsTableTracked,@batchSize,@IsReferenced,@PurgeFilter,@ExistsInTempDb
WHILE @@FETCH_STATUS = 0
BEGIN
	IF @PurgeFilter <> NULL OR @PurgeFilter <> ''
	BEGIN
		IF @IsTableTracked=1
			EXEC SYS.SP_CDC_DISABLE_TABLE @source_schema = N'dbo',@source_name = @TableName,  @capture_instance ='ALL';
		SET @sql='SELECT NULL WHILE @@ROWCOUNT > 0 DELETE TOP (' + CAST(@batchSize AS VARCHAR(20)) +  ') FROM ' + @TableName + ' WITH (TABLOCKX) WHERE ' + @PurgeFilter + ';'
		EXEC SYS.SP_EXECUTESQL @sql;

		IF @ExistsInTempDb = 1
		BEGIN
		 SELECT @TableName = base_object_name FROM  sys.synonyms where name = @TableName;
		END

		SET @sql='ALTER INDEX ALL ON ' + @TableName + ' REBUILD WITH (SORT_IN_TEMPDB = ON);'
		EXEC SYS.SP_EXECUTESQL @sql;
	END
	ELSE
	BEGIN
	    IF @ExistsInTempDb = 1
		BEGIN
			SELECT @TableName = base_object_name FROM  sys.synonyms where name = @TableName;
			SET @sql='Truncate table ' + @TableName
			EXEC SYS.SP_EXECUTESQL @sql;
		END
		ELSE IF @IsReplicated=1 OR @IsReferenced=1
		BEGIN
			SET @sql='SELECT NULL WHILE @@ROWCOUNT>0 DELETE TOP (' + CAST(@batchSize AS VARCHAR(20)) +  ') FROM ' + @TableName + ' WITH (TABLOCKX);'
			EXEC SYS.SP_EXECUTESQL @sql;
			SET @sql='ALTER INDEX ALL ON ' + @TableName + ' REBUILD WITH (SORT_IN_TEMPDB = ON);'
			EXEC SYS.SP_EXECUTESQL @sql;
		END
		ELSE IF @IsTableTracked=1
		BEGIN
			EXEC SYS.SP_CDC_DISABLE_TABLE @source_schema = N'dbo',@source_name = @TableName,  @capture_instance ='ALL'; --all is the @capture_instance used in fx CDC job
			SET @sql='truncate table ' + @TableName
			EXEC SYS.SP_EXECUTESQL @sql;
		END
		ELSE IF @IsReplicated=0
		BEGIN
			SET @sql='TRUNCATE TABLE ' + @TableName
			EXEC SYS.SP_EXECUTESQL @sql;
		END

	END

	FETCH NEXT FROM CUR INTO @TableName,@IsTableTracked,@batchSize,@IsReferenced,@PurgeFilter,@ExistsInTempDb
END
CLOSE CUR
DEALLOCATE CUR

DROP Table #tableList

GO
