SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[VP_GetVendorDetails]
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT
P.Id AS PartyId,
P.PartyNumber AS PartyNumber,
P.PartyName AS Name,
V.Type AS Type,
V.VendorProgramType,
V.Status AS Status
FROM Vendors V
JOIN Parties P on V.Id = P.Id
WHERE V.Status='Active' AND V.IsVendorProgram=1
END

GO
