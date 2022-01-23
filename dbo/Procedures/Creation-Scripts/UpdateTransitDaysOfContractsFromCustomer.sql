SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[UpdateTransitDaysOfContractsFromCustomer]
(
@CustomerId BIGINT,
@CustomerTransitDays INT,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;

CREATE TABLE #ContractIds(
	Id BIGINT PRIMARY KEY
)

INSERT INTO #ContractIds(Id)
SELECT ContractId FROM LeaseFinances WHERE CustomerId=@CustomerId AND IsCurrent=1

INSERT INTO #ContractIds(Id)
SELECT ContractId FROM LoanFinances WHERE CustomerId=@CustomerId AND IsCurrent=1

--For Leases/Loans/ProgressLoans
UPDATE CB 
SET CB.InvoiceTransitDays = @CustomerTransitDays, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM ContractBillings CB INNER JOIN #ContractIds CTR ON CB.Id = CTR.Id
WHERE CB.InvoiceTransitDays != @CustomerTransitDays

--For CPU Contracts
UPDATE CPUB 
SET CPUB.InvoiceTransitDays = @CustomerTransitDays, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM CPUBillings CPUB INNER JOIN CPUFinances CPUF ON CPUB.Id = CPUF.Id
WHERE CPUF.CustomerId=@CustomerId AND CPUB.InvoiceTransitDays != @CustomerTransitDays

DROP TABLE #ContractIds
END

GO
