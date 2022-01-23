SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetCustomerBasedReceivablesRangeForInvoiceSensitive]
(

	@ComputedProcessThroughDate DATETIME , 
	@LegalEntityIds NVARCHAR(MAX)
)
AS
BEGIN

SELECT Id INTO #LegalEntityIds FROM ConvertCSVToBigIntTable(@LegalEntityIds,',');

SELECT 
	Id AS CustomerId
	,DATEADD(DD,InvoiceLeaddays,@ComputedProcessThroughDate) DueDate
INTO #CustomersToBeProcessed
FROM Customers

SELECT
	C.Id AS ContractId
	,CASE WHEN InvoiceLeaddays IS NULL THEN @ComputedProcessThroughDate
		ELSE DATEADD(DD, InvoiceLeaddays, @ComputedProcessThroughDate)
	END AS DueDate
INTO #ContractsToBeProcessed
FROM Contracts C
LEFT JOIN ContractBillings CB On C.Id = CB.Id

Select R.CustomerId, COUNT(*) RecCount
INTO #Customers
FROM Receivables R
INNER JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId  
INNER JOIN #LegalEntityIds LE on R.LegalEntityId = LE.Id  
INNER JOIN #CustomersToBeProcessed C ON R.CustomerId = C.CustomerId
WHERE 
	R.IsActive =1 
	AND RD.IsActive =1 
	AND RD.IsTaxAssessed = 0 
	AND R.EntityType <> 'CT' 
	AND R.DueDate <= C.DueDate
GROUP BY R.CustomerId

INSERT INTO #Customers 
Select R.CustomerId, COUNT(*) RecCount
FROM Receivables R
INNER JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId  
INNER JOIN #LegalEntityIds LE on R.LegalEntityId = LE.Id  
INNER JOIN #ContractsToBeProcessed CT ON R.EntityId = CT.ContractId 
WHERE 
	R.IsActive =1 
	AND RD.IsActive =1 
	AND RD.IsTaxAssessed = 0 
	AND R.EntityType = 'CT' 
	AND R.DueDate <= CT.DueDate
GROUP BY R.CustomerId

SELECT CustomerId, Sum(RecCount) ReceivableDetailCount FROM #Customers GROUP BY CustomerId

END

GO
