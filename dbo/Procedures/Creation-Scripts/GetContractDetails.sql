SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetContractDetails]
(
@CustomerNumber nvarchar(MAX)
)
AS
SET NOCOUNT ON
BEGIN
CREATE TABLE #ContractDetails (Status nvarchar(20), Leases int , Loans int)
DECLARE @Leases INT = 0
DECLARE @Loans INT = 0
DECLARE @CustomerID BIGINT = 0
SELECT @CustomerID = Id
FROM Parties WHERE PartyNumber = @CustomerNumber
SELECT @Leases = COUNT(*)
FROM Contracts
INNER JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId
WHERE Contracts.Status <> 'Inactive'
AND Contracts.ContractType = 'Lease'
AND LeaseFinances.CustomerId = @CustomerID
SELECT @Loans = COUNT(*)
FROM Contracts
INNER JOIN LoanFinances ON Contracts.Id = LoanFinances.ContractId
WHERE Contracts.Status <> 'Inactive'
AND Contracts.ContractType = 'Loan'
AND LoanFinances.CustomerId = @CustomerID
insert into #ContractDetails(Status, Leases, Loans)
Select 'Active Contracts',@Leases,@Loans
SELECT @Leases = COUNT(*)
FROM Contracts
INNER JOIN LeaseFinances ON Contracts.Id = LeaseFinances.ContractId
WHERE Contracts.Status <> 'Inactive'
AND Contracts.ContractType = 'Lease'
AND LeaseFinances.CustomerId = @CustomerID
SELECT @Loans = COUNT(*)
FROM Contracts
INNER JOIN LoanFinances ON Contracts.Id = LoanFinances.ContractId
WHERE Contracts.Status <> 'Inactive'
AND Contracts.ContractType = 'Loan'
AND LoanFinances.CustomerId = @CustomerID
insert into #ContractDetails(Status, Leases, Loans)
Select 'Overdue Contracts',@Leases,@Loans
SELECT * From #ContractDetails
END

GO
