SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UpdateColumnForMigration]
(
      @TableName NVARCHAR(150),
      @ColumnName NVARCHAR(150),
      @Id MigrationIdCollection READONLY
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
DECLARE @Sql nvarchar(max) = '';

SELECT * INTO #MigrationIds
FROM @Id

SET @Sql ='DECLARE @UpdatedByTime DATETIMEOFFSET =SYSDATETIMEOFFSET();
 UPDATE '+ @TableName +  ' SET ' + @ColumnName + ' = 1, UpdatedById = 1, UpdatedTime = @UpdatedByTime WHERE Id IN (SELECT Id FROM #MigrationIds)';
EXEC (@Sql)
END

GO
