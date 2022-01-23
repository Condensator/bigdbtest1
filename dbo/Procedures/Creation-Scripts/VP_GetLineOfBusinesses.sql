SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[VP_GetLineOfBusinesses]
(
@PartyNumber NVARCHAR(20),
@VendorProgramType NVARCHAR(1),
@ProgramVendorNumber NVARCHAR(20) = NULL
)
AS
BEGIN
DECLARE @Query NVARCHAR(MAX)
DECLARE @PrgVendorQuery NVARCHAR(MAX)
DECLARE @DealerDistributerQuery NVARCHAR(MAX)
SET @Query =N'
SELECT
LOB.Name LineofBusinessName
FROM Vendors V
JOIN Parties P ON P.Id=V.Id AND P.PartyNumber = @PartyNumber'
SET @PrgVendorQuery = N'
JOIN LineofBusinesses LOB ON LOB.Id=V.LineofBusinessId'
SET @DealerDistributerQuery = N'
JOIN VendorsAssignedToDealers VD ON VD.VendorId = V.Id
JOIN LineofBusinesses LOB ON VD.LineofBusinessId=LOB.Id
JOIN Parties PrgVendor ON PrgVendor.PartyNumber = @ProgramVendorNumber'
IF(@VendorProgramType = 1)
SET @Query = @Query + @PrgVendorQuery
ELSE
SET @Query = @Query + @DealerDistributerQuery
EXEC sp_executesql @Query,N'
@PartyNumber NVARCHAR(40)
,@VendorProgramType NVARCHAR(1)
,@ProgramVendorNumber  NVARCHAR(20) = NULL'
,@PartyNumber
,@VendorProgramType
,@ProgramVendorNumber
END

GO
