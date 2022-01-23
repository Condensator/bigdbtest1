SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetCustomizationPacks](
	@WHERECLAUSE NVARCHAR(2000), 
	@ADVWHERECLAUSE NVARCHAR(2000), 
	@ORDERBYCLAUSE NVARCHAR(2000), 
	@StartingRowNumber int, 
	@EndingRowNumber int,
	@OrderBy NVARCHAR(6)
	)
AS
BEGIN


SET @ORDERBYCLAUSE = CASE WHEN @ORDERBYCLAUSE IS NOT NULL AND LEN(@ORDERBYCLAUSE) != 0 THEN @ORDERBYCLAUSE ELSE 'customizationPack.Id Desc' END 


SET @ADVWHERECLAUSE = CASE WHEN @ADVWHERECLAUSE IS NOT NULL AND LEN(@ADVWHERECLAUSE) != 0 THEN 'AND ' + @ADVWHERECLAUSE ELSE '' END 

DECLARE @SQLStatement NVARCHAR(MAX)=N'Select 
ROW_NUMBER() OVER (ORDER BY ORDERBYCLAUSE) AS ROW,
customizationPack.Id, 
[customizationPack.MetamodelContent] = null, 
[customizationPack.DomainAssembly] = null, 
[customizationPack.DatabaseUpdateScript] = null,
 customizationPack.PublisherTool, 
 customizationPack.IsActive, 
 customizationPack.Comments, 
 customizationPack.EffectiveDate, 
 customizationPack.CreatedById, customizationPack.CreatedTime, 
 customizationPack.UpdatedById, customizationPack.UpdatedTime, 
 customizationPack.[RowVersion] Into #Temp 
 from CustomizationPacks customizationPack 
WHERE 1=1
WHEREBUILDERCONDITION 
ADVANCEFILTERCONDITION 

ORDER BY customizationPack.IsActive asc  

DECLARE @TotalCount BigInt 
SELECT @TotalCount=  COUNT(*) FROM #Temp

select @TotalCount as [TotalRecordCount],
Id,
[customizationPack.MetamodelContent] as MetamodelContent,
[customizationPack.DomainAssembly] as DomainAssembly,
[customizationPack.DatabaseUpdateScript] as DatabaseUpdateScript,
PublisherTool,
IsActive,
Comments,
EffectiveDate,
CreatedById,CreatedTime,
UpdatedById,UpdatedTime,
[RowVersion]
from #Temp where ROW BETWEEN @StartingRowNumber AND @EndingRowNumber
'

SET @SQLStatement = REPLACE(@SQLStatement,'WHEREBUILDERCONDITION',@WHERECLAUSE)   
SET @SQLStatement = REPLACE(@SQLStatement,'ORDERBYCLAUSE',@ORDERBYCLAUSE) 
SET @SQLStatement = REPLACE(@SQLStatement,'ADVANCEFILTERCONDITION',@ADVWHERECLAUSE) 

EXEC sp_executesql @SQLStatement, N'@WHERECLAUSE NVARCHAR(2000), @ADVWHERECLAUSE NVARCHAR(2000), @ORDERBYCLAUSE NVARCHAR(2000), @StartingRowNumber int, @EndingRowNumber int,@OrderBy NVARCHAR(6)',@WHERECLAUSE, @ADVWHERECLAUSE, @ORDERBYCLAUSE,@StartingRowNumber, @EndingRowNumber,@OrderBy;

END

GO
