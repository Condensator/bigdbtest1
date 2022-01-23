SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[VP_GetSalesRepAndSalesSupportEmailForQuoteRequest]
(
@PartyId BIGINT,
@SaleRepEmail NVARCHAR(70) OUT,
@SaleSupportEmail NVARCHAR(70) OUT
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT
@SaleRepEmail = U.Email
FROM EmployeesAssignedToParties E
JOIN Users U on E.EmployeeId=U.Id
JOIN RoleFunctions RF ON E.RoleFunctionId = RF.Id
WHERE E.PartyId = @PartyId
AND E.IsPrimary = 1
AND RF.Name = 'Sales Rep'
AND E.IsActive=1
AND E.PartyRole = 'Vendor'
SELECT
@SaleSupportEmail = U.Email
FROM EmployeesAssignedToParties E
JOIN Users U on E.EmployeeId=U.Id
JOIN RoleFunctions RF ON E.RoleFunctionId = RF.Id
WHERE E.PartyId = @PartyId
AND E.IsPrimary = 1
AND RF.Name = 'Sales Support'
AND E.IsActive=1
AND E.PartyRole = 'Vendor'
END

GO
