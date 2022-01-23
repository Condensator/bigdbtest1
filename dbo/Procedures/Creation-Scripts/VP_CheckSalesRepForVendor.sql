SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[VP_CheckSalesRepForVendor]
(
@CurrentVendorId BIGINT
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT DISTINCT Count(*) AS IsSalesRep FROM  [dbo].[EmployeesAssignedToParties] AS EAV
JOIN RoleFunctions AS RFUN ON EAV.RoleFunctionId = RFUN.Id
WHERE RFUN.IsActive =1 AND RFUN.Name='Sales Rep'
AND EAV.IsActive=1 AND EAV.IsPrimary=1
AND EAV.PartyId=@CurrentVendorId
AND EAV.PartyRole = 'Vendor'
END

GO
