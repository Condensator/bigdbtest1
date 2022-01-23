SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ReceivableAging]
(
@LegalEntityNumber NVARCHAR(MAX) = NULL,
@CustomerNumber NVARCHAR(40) = NULL,
@CustomerName NVARCHAR(MAX) = NULL,
@ContractSequenceNumber NVARCHAR(MAX) = NULL,
@LineOfBusiness NVARCHAR(MAX) = NULL,
@Currency NVARCHAR(10) = NULL,
@ReceivableType NVARCHAR(MAX) = NULL,
@AsOfDate DATETIME = NULL,
@Culture NVARCHAR(10)
)
AS

BEGIN

--DECLARE @LegalEntityNumber NVARCHAR(MAX) = '100100',
--@CustomerNumber NVARCHAR(40) = '7180',
--@CustomerName NVARCHAR(MAX) = NULL,
--@ContractSequenceNumber NVARCHAR(MAX) = NULL,
--@LineOfBusiness NVARCHAR(MAX) = NULL,
--@Currency NVARCHAR(10) = NULL,
--@ReceivableType NVARCHAR(MAX) = '1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25',
--@AsOfDate DATETIME = '2020-04-30',
--@Culture NVARCHAR(10) = 'en-US'

SET NOCOUNT ON

IF @AsofDate IS NULL
BEGIN
	SET @AsofDate = CONVERT(CHAR(10),GETDATE(),110)
END

DECLARE @SQLStatement NVARCHAR(MAX)

SET @SQLStatement = '
SELECT ID INTO #ReceivableTypeTemp FROM dbo.ConvertCSVToBigIntTable(@ReceivableType,'','')

SELECT
	Receivables.Id ReceivableId,
	Parties.Id PartyId,
	Receivables.LegalEntityId,
	Receivables.EntityId EntityId,
	Receivables.EntityType,
	ReceivableCodes.ReceivableTypeId,
	DATEDIFF(dd,Receivables.DueDate,@AsOfDate) AS [AgeInDays],
	Receivables.TotalAmount_Currency,
	Receivables.TotalAmount_Amount
INTO #Receivables
FROM Receivables
INNER JOIN ReceivableCodes
	ON Receivables.ReceivableCodeId = ReceivableCodes.Id
INNER JOIN #ReceivableTypeTemp RT
	ON ReceivableCodes.ReceivableTypeId = RT.ID
INNER JOIN LegalEntities
	ON Receivables.LegalEntityId = LegalEntities.Id
INNER JOIN Parties
	ON Receivables.CustomerId = Parties.Id
LEASECONDITION
FILTERCONDITIONS

;WITH CTE_LineOfBusiness AS
(
	SELECT 
		r.ReceivableId,
		s.LineofBusinessId
	FROM #Receivables r
	JOIN dbo.Sundries s ON s.ReceivableId = r.ReceivableId AND R.EntityType=''CU''

	UNION ALL

	SELECT 
		r.ReceivableId,
		sd.LineofBusinessId
	FROM #Receivables r
	JOIN dbo.SecurityDeposits sd ON sd.ReceivableId = r.ReceivableId AND R.EntityType=''CU''
	
	UNION ALL

	SELECT 
		r.ReceivableId,
		sr.LineofBusinessId
	FROM #Receivables r
	INNER JOIN dbo.SundryRecurringPaymentSchedules srps ON srps.ReceivableId = r.ReceivableId AND R.EntityType=''CU''
	INNER JOIN dbo.SundryRecurrings sr ON srps.SundryRecurringId = sr.Id
)
SELECT lobd.ReceivableId,lobd.LineOfBusinessId, CAST(NULL AS NVARCHAR(100)) SequenceNumber
INTO #CULOBDetails
FROM  CTE_LineOfBusiness lobd
INNER JOIN LineofBusinesses ON LineofBusinesses.Id = lobd.LineOfBusinessId
LINEOFBUSINESSECONDITION

INSERT INTO #CULOBDetails
SELECT 
	r.ReceivableId,
	C.LineOfBusinessId,
	C.SequenceNumber
FROM #Receivables r
JOIN Contracts C
	ON C.Id = R.EntityId AND R.EntityType=''CT''
INNER JOIN LineofBusinesses ON LineofBusinesses.Id = C.LineOfBusinessId
LINEOFBUSINESSECONDITION

SELECT Id,ReceivableId,Balance_Amount,BillToId INTO #ReceivableDetails FROM ReceivableDetails Where ReceivableId IN (Select ReceivableId FROM #Receivables)

SELECT
	ReceivableTypes.Name,
	Parties.PartyNumber AS [Customer #],
	Parties.PartyName AS [Customer Name],
	#CULOBDetails.SequenceNumber AS [Sequence #],
	LegalEntities.LegalEntityNumber AS [Legal Entity #],
	LineofBusinesses.Name AS [Line of Business],
	#Receivables.TotalAmount_Currency AS [Currency],
	#Receivables.AgeInDays,
	#Receivables.TotalAmount_Amount AS [Total],
	ISNULL(SUM(#ReceivableDetails.Balance_Amount),0) AS [Balance],
	ISNULL(SUM(#ReceivableDetails.Balance_Amount),0) AS [Current],
	ISNULL(SUM(#ReceivableDetails.Balance_Amount),0) AS [1 - 30 Days],
	ISNULL(SUM(#ReceivableDetails.Balance_Amount),0) As [31 - 60 Days],
	ISNULL(SUM(#ReceivableDetails.Balance_Amount),0) AS [61 - 90 Days],
	ISNULL(SUM(#ReceivableDetails.Balance_Amount),0) AS [91 - 120 Days],
	ISNULL(SUM(#ReceivableDetails.Balance_Amount),0) AS [Over 120 days],
	PartyContacts.FullName AS [Contact Person],
	ISNULL(PartyAddresses.AddressLine1,ISNULL(PartyAddresses.HomeAddressLine1,''''))+'', ''+
	ISNULL(PartyAddresses.City,ISNULL(PartyAddresses.HomeCity,''''))+'', ''+
	ISNULL(EntityResourceForState.[Value],ISnull(Office.LongName,Home.LongName))+'', ''+
	ISNULL(PartyAddresses.PostalCode,ISNULL(PartyAddresses.HomePostalCode,''''))
	AS [Contact Address]
INTO #InvoiceList
FROM #Receivables 
INNER JOIN Receivables
	ON #Receivables.ReceivableId = Receivables.Id
INNER JOIN #ReceivableDetails
	ON #ReceivableDetails.ReceivableId = #Receivables.ReceivableId
INNER JOIN ReceivableTypes
	ON #Receivables.ReceivableTypeId = ReceivableTypes.Id
INNER JOIN LegalEntities
	ON #Receivables.LegalEntityId = LegalEntities.Id
INNER JOIN Parties
	ON #Receivables.PartyId = Parties.Id
INNER JOIN #CULOBDetails 
	ON #Receivables.ReceivableId = #CULOBDetails.ReceivableId
INNER JOIN LineofBusinesses
	ON #CULOBDetails.LineofBusinessId = LineofBusinesses.Id
INNER JOIN BillToes
	ON BillToes.Id = #ReceivableDetails.BillToId
INNER JOIN dbo.PartyAddresses
	ON PartyAddresses.PartyId = Parties.Id
	AND PartyAddresses.Id = BillToes.BillingAddressId
LEFT JOIN dbo.States Office
	ON Office.Id = PartyAddresses.StateId
LEFT JOIN dbo.States Home
	ON Home.Id = PartyAddresses.HomeStateId
LEFT JOIN dbo.PartyContacts
	ON PartyContacts.PartyId = Parties.Id
	AND PartyContacts.IsActive = 1
	AND BillToes.BillingContactPersonId = PartyContacts.Id
LEFT JOIN EntityResources EntityResourceForState
	ON  EntityResourceForState.EntityId = ISNULL(Office.Id,Home.Id)
	AND EntityResourceForState.EntityType = ''State''
	AND EntityResourceForState.Name = ''LongName''
	AND EntityResourceForState.Culture = @Culture
GROUP BY
ReceivableTypes.Name,
Parties.Id
,Parties.PartyNumber
,Parties.PartyName
,#CULOBDetails.SequenceNumber
,LegalEntities.LegalEntityNumber
,LineofBusinesses.Name
,#Receivables.TotalAmount_Currency
,PartyContacts.FullName,PartyAddresses.AddressLine1,PartyAddresses.HomeAddressLine1
,PartyAddresses.City,PartyAddresses.HomeCity,ISNULL(EntityResourceForState.[Value],ISnull(Office.LongName,Home.LongName)),PartyAddresses.PostalCode,PartyAddresses.HomePostalCode
,#Receivables.AgeInDays
,#Receivables.TotalAmount_Amount

UPDATE dbo.#InvoiceList
SET
dbo.#InvoiceList.[Current] = CASE WHEN dbo.#InvoiceList.AgeInDays <= 0 THEN dbo.#InvoiceList.Balance ELSE 0 END,
dbo.#InvoiceList.[1 - 30 Days] = CASE WHEN (dbo.#InvoiceList.AgeInDays > 0 AND dbo.#InvoiceList.AgeInDays <= 30) THEN dbo.#InvoiceList.Balance ELSE 0 END,
dbo.#InvoiceList.[31 - 60 Days] = CASE WHEN (dbo.#InvoiceList.AgeInDays > 30 AND dbo.#InvoiceList.AgeInDays <= 60) THEN dbo.#InvoiceList.Balance ELSE 0 END,
dbo.#InvoiceList.[61 - 90 Days] = CASE WHEN (dbo.#InvoiceList.AgeInDays > 60 AND dbo.#InvoiceList.AgeInDays <= 90) THEN dbo.#InvoiceList.Balance ELSE 0 END,
dbo.#InvoiceList.[91 - 120 Days] = CASE WHEN (dbo.#InvoiceList.AgeInDays > 90 AND dbo.#InvoiceList.AgeInDays <= 120) THEN dbo.#InvoiceList.Balance ELSE 0 END,
dbo.#InvoiceList.[Over 120 Days] = CASE WHEN dbo.#InvoiceList.AgeInDays > 120 THEN dbo.#InvoiceList.Balance Else 0 END
UPDATE dbo.#InvoiceList
SET dbo.#InvoiceList.[Total] = dbo.#InvoiceList.[Current] + dbo.#InvoiceList.[1 - 30 Days]+dbo.#InvoiceList.[31 - 60 Days]+dbo.#InvoiceList.[61 - 90 Days]+dbo.#InvoiceList.[91 - 120 Days]+dbo.#InvoiceList.[Over 120 Days]
SELECT
[Customer #],
[Customer Name],
[Currency],
SUM([Total]) AS [Total],
SUM([Balance]) AS [Balance],
SUM([Current]) AS [Current],
SUM([1 - 30 Days]) [1 - 30 Days],
SUM([31 - 60 Days]) [31 - 60 Days],
SUM([61 - 90 Days]) [61 - 90 Days],
SUM([91 - 120 Days]) [91 - 120 Days],
SUM([Over 120 days]) [Over 120 Days],
[Contact Person],
[Contact Address],
[Sequence #],
[Legal Entity #],
[Line of Business]
FROM #InvoiceList
GROUP BY
[Customer #],
[Customer Name],
[Currency],
[Contact Person],
[Contact Address],
[Sequence #],
[Legal Entity #],
[Line of Business]

DROP TABLE #InvoiceList
DROP TABLE #Receivables
DROP TABLE #CULOBDetails 
DROP TABLE #ReceivableTypeTemp'

DECLARE @FilterConditions NVARCHAR(MAX)
DECLARE @LeaseConditions NVARCHAR(MAX) = ''
DECLARE @LineofBusinessConditions NVARCHAR(MAX) = ''

SET @FilterConditions = '
WHERE Receivables.IsActive = 1
AND ((Receivables.IsDummy = 1 AND Receivables.IsDSL = 1) OR (Receivables.IsDummy = 0))
AND	Receivables.TotalBalance_Amount <> 0 '

IF @LegalEntityNumber IS NOT NULL
BEGIN
	SET @FilterConditions = @FilterConditions +  ' AND LegalEntities.LegalEntityNumber in (select value from String_split(@LegalEntityNumber,'','')) '
END

IF @CustomerNumber IS NOT NULL
BEGIN
	SET @FilterConditions = @FilterConditions +  ' AND Parties.PartyNumber = @CustomerNumber '
END

IF @CustomerName IS NOT NULL
BEGIN
	SET @FilterConditions = @FilterConditions +  ' AND Parties.PartyName = @CustomerName '
END

IF @ContractSequenceNumber IS NOT NULL
BEGIN
	SET @LeaseConditions = 'INNER JOIN Contracts
		ON Receivables.EntityId = Contracts.Id
		AND Receivables.EntityType = ''CT'''

	SET @FilterConditions = @FilterConditions +  ' AND  Contracts.SequenceNumber = @ContractSequenceNumber'
END

IF @LineOfBusiness IS NOT NULL
BEGIN
	SET @LineofBusinessConditions = @LineofBusinessConditions +  ' AND LineofBusinesses.Name = @LineOfBusiness '
END

IF @Currency IS NOT NULL
BEGIN
	SET @FilterConditions = @FilterConditions +  ' AND Receivables.TotalAmount_Currency = @Currency '
END

SET @SQLStatement = REPLACE(@SQLStatement, 'LEASECONDITION', @LeaseConditions)
SET @SQLStatement = REPLACE(@SQLStatement, 'FILTERCONDITIONS', @FilterConditions)
SET @SQLStatement = REPLACE(@SQLStatement, 'LINEOFBUSINESSECONDITION', @LineofBusinessConditions)

print @SQLStatement

EXEC sp_executesql @SQLStatement, N'
@LegalEntityNumber NVARCHAR(MAX) = NULL
,@CustomerNumber NVARCHAR(40) = NULL
,@CustomerName NVARCHAR(MAX) = NULL
,@ContractSequenceNumber NVARCHAR(MAX) = NULL
,@LineOfBusiness NVARCHAR(MAX) = NULL
,@Currency NVARCHAR(10) = NULL
,@ReceivableType NVARCHAR(MAX) = NULL
,@AsOfDate DATETIME = NULL
,@Culture NVARCHAR(10)= NULL'
,@LegalEntityNumber
,@CustomerNumber
,@CustomerName
,@ContractSequenceNumber
,@LineOfBusiness
,@Currency
,@ReceivableType
,@AsOfDate
,@Culture
END


GO
