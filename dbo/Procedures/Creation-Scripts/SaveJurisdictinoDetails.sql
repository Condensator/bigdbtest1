SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SaveJurisdictinoDetails]
@mytable TableData readonly
AS
BEGIN
SET NOCOUNT ON
INSERT INTO JurisdictionDetails
(PostalCode
,JurisdictionId
,CreatedById
,IsActive,CreatedTime)
SELECT *, 1, GETDATE()
FROM  @mytable;
END

GO
