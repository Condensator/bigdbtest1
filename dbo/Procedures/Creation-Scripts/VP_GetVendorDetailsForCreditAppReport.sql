SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[VP_GetVendorDetailsForCreditAppReport]
(
@PartyNumber NVARCHAR(MAX),
@IsProgramVendor NVARCHAR(1)
)
AS
BEGIN
DECLARE @Query NVARCHAR(MAX)
DECLARE @PrgVendorQuery NVARCHAR(MAX)
DECLARE @DealerDistributerQuery NVARCHAR(MAX)
SET @Query =N'
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT
V.Id As PartyId,
PV.PartyNumber As PartyNumber,
PV.PartyName AS Name,
V.Type AS Type,
V.Status AS Status
FROM Parties P
JOINCONDITION
WHERE P.PartyNumber = @PartyNumber
AND V.Status=''Active''
AND D.IsAssigned = 1'
SET @PrgVendorQuery = N'
JOIN ProgramsAssignedToAllVendors D on P.Id = D.ProgramVendorId
JOIN Parties PV ON PV.Id = D.VendorId
JOIN Vendors V ON PV.Id = V.Id'
SET @DealerDistributerQuery = N'
JOIN ProgramsAssignedToAllVendors D on P.Id = D.VendorId
JOIN Parties PV ON PV.Id = D.ProgramVendorId
JOIN Vendors V ON PV.Id = V.Id'
IF(@IsProgramVendor = 1)
SET @Query =  REPLACE(@Query, 'JOINCONDITION', @PrgVendorQuery);
ELSE
SET @Query =  REPLACE(@Query, 'JOINCONDITION', @DealerDistributerQuery);
EXEC sp_executesql @Query,N'
@PartyNumber NVARCHAR(40)
,@IsProgramVendor NVARCHAR(1)'
,@PartyNumber
,@IsProgramVendor
END

GO
