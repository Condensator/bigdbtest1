SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[SplitAmountColumns]
(
@TableName NVARCHAR(100),
@UpdateColumnName NVARCHAR(100),
@UserId BIGINT,
@SplitByType NVARCHAR(20),
@Time DATETIMEOFFSET,
@JobInstanceId BigInt,
@PrioritizeBalanceColumn BIT
)
RETURNS NVARCHAR(MAX)
--Declare @TableName NVarchar(100);
--Declare @UpdateColumnName nvarchar(100)
--Declare @SplitByType NVARCHAR(MAX)
--Declare @UserId INT
--Set @TableName = 'Assets'
--Set @UpdateColumnName = 'Id'
--Set @SplitByType = 'SplitByAmount'
--Set @UserId = 1
BEGIN
DECLARE @JobInstanceIdInString varchar(30) = CAST(@JobInstanceId as varchar(30))/*used in dynamic queries building; instead of type casting in all places we use this variable*/
DECLARE @TableColumns TABLE (Id BIGINT IDENTITY(1,1), Name VARCHAR(100));
IF(@PrioritizeBalanceColumn = 0)
BEGIN
INSERT INTO @TableColumns
SELECT COLUMN_NAME [Name] FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @TableName
AND DATA_TYPE = 'Decimal' And COLUMN_NAME Like '%_Amount%'  
END
ELSE
BEGIN
INSERT INTO @TableColumns
SELECT COLUMN_NAME [Name] FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @TableName
AND DATA_TYPE = 'Decimal' And COLUMN_NAME Like '%_Amount%' and COLUMN_NAME like '%balance%'
INSERT INTO @TableColumns
SELECT COLUMN_NAME [Name] FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @TableName
AND DATA_TYPE = 'Decimal' And COLUMN_NAME Like '%_Amount%' and COLUMN_NAME not like '%balance%'
END
DECLARE @UpdateQuery NVARCHAR(MAX)
DECLARE @ColumnName NVARCHAR(MAX)
DECLARE @totalRecords INT
DECLARE @Count INT
SELECT @Count = 1
SELECT @UpdateQuery = 'DECLARE @Amount NVARCHAR(20) ';
SELECT @ColumnName = '';
SELECT @totalRecords = COUNT(Id) FROM @TableColumns
WHILE (@Count <= @totalRecords)
BEGIN
SELECT @ColumnName = Name FROM @TableColumns WHERE Id = @Count
SET @UpdateQuery = @UpdateQuery + ' Update ' + @TableName +' Set ' + @ColumnName + ' = Round(' + @ColumnName + ' * AssetSplitTemp.Prorate ,2)
From ' + @TableName + ' JOIN AssetSplitTemp On AssetSplitTemp.NewId = ' + @TableName + '.' + @UpdateColumnName + ' Where AssetSplitTemp.IsLast = 0 and AssetSplitTemp.JobInstanceId = '+@JobInstanceIdInString +';';
SET @UpdateQuery = @UpdateQuery +  '; With CTE_Balance as
(Select AssetSplitTemp.OldId ,  SUM(' + @ColumnName + ') AS Amount From ' + @TableName +
' Join AssetSplitTemp On AssetSplitTemp.NewId = ' + @TableName + '.' + @UpdateColumnName + ' Where AssetSplitTemp.IsLast = 0 and AssetSplitTemp.JobInstanceId ='+@JobInstanceIdInString +' Group By AssetSplitTemp.OldId ) ';
SET @UpdateQuery = @UpdateQuery + ' Update ' + @TableName +' Set ' + @ColumnName + ' = ' + @ColumnName  + ' -  CTE_Balance.Amount
From ' + @TableName + ' JOIN AssetSplitTemp On AssetSplitTemp.NewId = ' + @TableName + '.' + @UpdateColumnName + '
JOIN CTE_Balance On AssetSplitTemp.OldId = CTE_Balance.OldId Where AssetSplitTemp.IsLast = 1 and AssetSplitTemp.JobInstanceId = '+@JobInstanceIdInString +';';
SELECT @Count = @Count + 1
END
IF @SplitByType = 'SplitByFeature'
BEGIN
SET @UpdateQuery = @UpdateQuery + ' Update ' + @TableName +' Set  CreatedById = ' + CAST(@UserId As NVARCHAR(10)) + ' , CreatedTime = ''' + CAST(@Time As NVARCHAR(MAX)) + ''', UpdatedById = Null, UpdatedTime = Null
From ' + @TableName + ' JOIN AssetSplitTemp On AssetSplitTemp.NewId = ' + @TableName + '.' + @UpdateColumnName + ' Where AssetSplitTemp.IsLast = 0 and AssetSplitTemp.JobInstanceId = '+@JobInstanceIdInString +';';
SET @UpdateQuery = @UpdateQuery + ' Update ' + @TableName +' Set UpdatedById = '+ CAST(@UserId As NVARCHAR(10)) + ' , UpdatedTime = '''+ CAST(@Time As NVARCHAR(MAX)) + '''
From ' + @TableName + ' JOIN AssetSplitTemp On AssetSplitTemp.NewId = ' + @TableName + '.' + @UpdateColumnName + ' Where AssetSplitTemp.IsLast = 1 and AssetSplitTemp.JobInstanceId = '+@JobInstanceIdInString +';';
END
ELSE
BEGIN
SET @UpdateQuery = @UpdateQuery + ' Update ' + @TableName +' Set  CreatedById = ' + CAST(@UserId As NVARCHAR(10)) + ' ,  CreatedTime = ''' + CAST(@Time As NVARCHAR(MAX)) + ''', UpdatedById = Null, UpdatedTime = Null
From ' + @TableName + ' JOIN AssetSplitTemp On AssetSplitTemp.NewId = ' + @TableName + '.' + @UpdateColumnName + ' where AssetSplitTemp.JobInstanceId = '+@JobInstanceIdInString +';';
END
RETURN @UpdateQuery
END

GO
