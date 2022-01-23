SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetStoredProcedureParameters]
(	
   @procedureName nvarchar(128)
)
AS
SET NOCOUNT ON
BEGIN

	select parameters.name as [Name]
	from sys.parameters 
	inner join sys.procedures on parameters.object_id = procedures.object_id  
	where procedures.name = @procedureName

END


GO
