SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetFirstRowIdForDynamicLookup]
(
@tableName NVARCHAR(max)
)

AS
BEGIN

DECLARE @entity NVARCHAR(max);
SET @entity = N'Select MIN(Id) as Id from #Temp'
SET @entity = Replace(@entity,'#Temp',@tableName)
EXEC sp_executesql @entity, N'@tableName nvarchar(max)', @tableName
END


GO
