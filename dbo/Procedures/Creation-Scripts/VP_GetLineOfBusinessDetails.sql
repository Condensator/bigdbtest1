SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[VP_GetLineOfBusinessDetails]
(
@PartyNumber NVARCHAR(40),
@Count INT OUTPUT
)
AS
BEGIN
SELECT
@Count = COUNT(*)
FROM Vendors V
JOIN Parties P ON P.Id=V.Id
WHERE PartyNumber=@PartyNumber
AND V.LineofBusinessId IS NOT NULL
END

GO
