SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetCustomerBasedReceivablesRangeForNonInvoiceSensitive]
(

	@ComputedProcessThroughDate DATETIME , 
	@LegalEntityIds NVARCHAR(MAX)
)
AS

BEGIN

SELECT 
	Id 
INTO #LegalEntityIds 
FROM ConvertCSVToBigIntTable(@LegalEntityIds,',')

Select 
	CustomerId, 
	COUNT(*) ReceivableDetailCount
FROM Receivables R
INNER JOIN ReceivableDetails RD 
	ON R.Id = RD.ReceivableId  
INNER JOIN #LegalEntityIds LE 
	ON R.LegalEntityId = LE.Id  
WHERE 
	R.IsActive =1 
	AND RD.IsActive =1 
	AND RD.IsTaxAssessed = 0 
	AND R.DueDate <= @ComputedProcessThroughDate
GROUP BY CustomerId
END

GO
