SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CheckStoredProcedureExist]
(	
   @procedureName nvarchar(128)
)
AS
SET NOCOUNT ON
BEGIN

Select 1 as Id from sys.procedures where object_id=OBJECT_ID(@procedureName)

END

GO
