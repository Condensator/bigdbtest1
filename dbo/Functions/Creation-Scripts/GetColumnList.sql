SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetColumnList]
(
@table_name varchar(776)     -- The table/view for which the INSERT statements will be generated using the existing data
)
RETURNS VARCHAR(max)
AS
--Declare  @table_name varchar(776)
--set @table_name = 'Assets'
BEGIN
--SELECT dbo.GetColumnList('Inventory_UDF')
DECLARE @target_table varchar(776) 	-- Use this parameter to specify a different table name into which the data will be inserted
DECLARE @include_timestamp bit  		-- Specify 1 for this parameter, if you want to include the TIMESTAMP/ROWVERSION column's data in the INSERT statement
DECLARE @owner varchar(64) 		-- Use this parameter if you are not the owner of the table
DECLARE @ommit_identity bit 		-- Use this parameter to ommit the identity columns
DECLARE @cols_to_include varchar(8000)	-- List of columns to be included in the INSERT statement
DECLARE @cols_to_exclude varchar(8000)	-- List of columns to be excluded from the INSERT statement
DECLARE @ommit_computed_cols bit 		-- When 1, computed columns will not be included in the INSERT statement
SET @target_table  = NULL
SET @include_timestamp = 0
SET @owner = NULL
SET @ommit_identity = 0
SET @cols_to_include = NULL
SET @cols_to_exclude = NULL
SET @ommit_computed_cols = 0
--Variable declarations
DECLARE	@Column_ID int,@Column_List varchar(8000), @Column_Name varchar(128), @Start_Insert varchar(786),
@Data_Type varchar(128), @Actual_Values varchar(8000), @IDN varchar(128)
--Variable Initialization
SET @IDN = ''
SET @Column_ID = 0
SET @Column_Name = ''
SET @Column_List = ''
SET @Actual_Values = ''
IF @owner IS NULL
BEGIN
SET @Start_Insert = 'INSERT INTO ' + '[' + RTRIM(COALESCE(@target_table,@table_name)) + ']'
END
ELSE
BEGIN
SET @Start_Insert = 'INSERT ' + '[' + LTRIM(RTRIM(@owner)) + '].' + '[' + RTRIM(COALESCE(@target_table,@table_name)) + ']'
END
--To get the first column's ID
SELECT	@Column_ID = MIN(ORDINAL_POSITION)
FROM	INFORMATION_SCHEMA.COLUMNS (NOLOCK)
WHERE 	TABLE_NAME = @table_name AND
(@owner IS NULL OR TABLE_SCHEMA = @owner)
--Loop through all the columns of the table, to get the column names and their data types
WHILE @Column_ID IS NOT NULL
BEGIN
SELECT 	@Column_Name = QUOTENAME(COLUMN_NAME),
@Data_Type = DATA_TYPE
FROM 	INFORMATION_SCHEMA.COLUMNS (NOLOCK)
WHERE 	ORDINAL_POSITION = @Column_ID AND
TABLE_NAME = @table_name AND
(@owner IS NULL OR TABLE_SCHEMA = @owner)
IF @cols_to_include IS NOT NULL --Selecting only user specified columns
BEGIN
IF CHARINDEX( '''' + SUBSTRING(@Column_Name,2,LEN(@Column_Name)-2) + '''',@cols_to_include) = 0
BEGIN
GOTO SKIP_LOOP
END
END
IF @cols_to_exclude IS NOT NULL --Selecting only user specified columns
BEGIN
IF CHARINDEX( '''' + SUBSTRING(@Column_Name,2,LEN(@Column_Name)-2) + '''',@cols_to_exclude) <> 0
BEGIN
GOTO SKIP_LOOP
END
END
--Making sure to output SET IDENTITY_INSERT ON/OFF in case the table has an IDENTITY column
IF (SELECT COLUMNPROPERTY( OBJECT_ID(QUOTENAME(COALESCE(@owner,USER_NAME())) + '.' + @table_name),SUBSTRING(@Column_Name,2,LEN(@Column_Name) - 2),'IsIdentity')) = 1
BEGIN
IF @ommit_identity = 0 --Determing whether to include or exclude the IDENTITY column
SET @IDN = @Column_Name
ELSE
GOTO SKIP_LOOP
END
--Making sure whether to output computed columns or not
IF @ommit_computed_cols = 1
BEGIN
IF (SELECT COLUMNPROPERTY( OBJECT_ID(QUOTENAME(COALESCE(@owner,USER_NAME())) + '.' + @table_name),SUBSTRING(@Column_Name,2,LEN(@Column_Name) - 2),'IsComputed')) = 1
BEGIN
GOTO SKIP_LOOP
END
END
--Determining the data type of the column and depending on the data type, the VALUES part of
--the INSERT statement is generated. Care is taken to handle columns with NULL values. Also
--making sure, not to lose any data from flot, real, money, smallmomey, datetime columns
SET @Actual_Values = @Actual_Values  +
CASE
WHEN @Data_Type IN ('char','varchar','nchar','nvarchar')
THEN
'COALESCE('''''''' + REPLACE(RTRIM(' + @Column_Name + '),'''''''','''''''''''')+'''''''',''NULL'')'
WHEN @Data_Type IN ('datetime','smalldatetime')
THEN
'COALESCE('''''''' + RTRIM(CONVERT(char,' + @Column_Name + ',109))+'''''''',''NULL'')'
WHEN @Data_Type IN ('uniqueidentifier')
THEN
'COALESCE('''''''' + REPLACE(CONVERT(char(255),RTRIM(' + @Column_Name + ')),'''''''','''''''''''')+'''''''',''NULL'')'
WHEN @Data_Type IN ('text','ntext')
THEN
'COALESCE('''''''' + REPLACE(CONVERT(char(8000),' + @Column_Name + '),'''''''','''''''''''')+'''''''',''NULL'')'
WHEN @Data_Type IN ('binary','varbinary')
THEN
'COALESCE(RTRIM(CONVERT(char,' + 'CONVERT(int,' + @Column_Name + '))),''NULL'')'
WHEN @Data_Type IN ('timestamp','rowversion')
THEN
CASE
WHEN @include_timestamp = 0
THEN
'''DEFAULT'''
ELSE
'COALESCE(RTRIM(CONVERT(char,' + 'CONVERT(int,' + @Column_Name + '))),''NULL'')'
END
WHEN @Data_Type IN ('float','real','money','smallmoney')
THEN
'COALESCE(LTRIM(RTRIM(' + 'CONVERT(char, ' +  @Column_Name  + ',2)' + ')),''NULL'')'
ELSE
'COALESCE(LTRIM(RTRIM(' + 'CONVERT(char, ' +  @Column_Name  + ')' + ')),''NULL'')'
END   + '+' +  ''',''' + ' + '
--Generating the column list for the INSERT statement
SET @Column_List = @Column_List +  @Column_Name + ','
SKIP_LOOP: --The label used in GOTO
SELECT 	@Column_ID = MIN(ORDINAL_POSITION)
FROM 	INFORMATION_SCHEMA.COLUMNS (NOLOCK)
WHERE 	TABLE_NAME = @table_name AND
ORDINAL_POSITION > @Column_ID AND
(@owner IS NULL OR TABLE_SCHEMA = @owner)
END
SET @Column_List = LEFT(@Column_List,len(@Column_List) - 1)
SET @Column_List = REPLACE(@Column_List, '[RowVersion],','');
SET @Column_List = REPLACE(@Column_List, ',,',',');
SET @Column_List = REPLACE(@Column_List, ',[RowVersion]','');
SET @Column_List = REPLACE(@Column_List, ',,',',');
SET @Column_List = REPLACE(@Column_List, '[Id],','');
SET @Column_List = REPLACE(@Column_List, ',,',',');
RETURN @Column_List
END

GO
