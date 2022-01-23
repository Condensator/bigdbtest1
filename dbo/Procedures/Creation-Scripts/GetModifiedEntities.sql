SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*
Input
	Source		RowVersion		targettable		RowVersion	UpdateById
	1			0XAABBCC			1			0XAABBCC		1
	2			0XAABBDF			2			0XAABBGG		NULL
	3			0XAABBEE			3			0XAABBEE		NULL
	4			0XAABBEE			4			0XAABBEF		10
	4			0XAABBEB			4			0XAABBEF		10
The above kind of input should return only Rows 2 and 4 
*/

CREATE PROC [dbo].[GetModifiedEntities]
(
 @val [dbo].[EntitiesToCheck] READONLY,
 @TableName NVARCHAR(128) 
)
AS
SET NOCOUNT ON;

DECLARE @sql NVARCHAR(max);

SET @sql = 'SELECT targetTable.Id FROM '+ @TableName +' targetTable INNER JOIN @entities source ON source.Id = targetTable.Id WHERE targetTable.RowVersion <> source.RowVersion'

EXECUTE sp_executesql @sql , N'@entities [dbo].[EntitiesToCheck] READONLY' , @entities = @val

GO
