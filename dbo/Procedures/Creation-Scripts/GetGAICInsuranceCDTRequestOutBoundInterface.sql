SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetGAICInsuranceCDTRequestOutBoundInterface] (@UpdatedTime DateTimeOffset)
AS
BEGIN
SET NOCOUNT ON;
CREATE TABLE #AssetSerialNumbers
	(
		AssetId BIGINT,
		SerialNumber nvarchar(100)
	)

	INSERT INTO #AssetSerialNumbers
		SELECT AssetId, MAX (ASN.SerialNumber) as SerialNumber from AssetSerialNumbers ASN inner join Assets 
		Asset on ASN.AssetId = Asset.Id where ASN.IsActive = 1  group by AssetId
		having COUNT(ASN.SerialNumber) = 1
		

;WITH CTE_AVHistory AS
(
Select
LeaseAssets.AssetId
,LeaseFinanceId = LeaseFinances.Id
,AssetValueHistoryId = Max(AssetValueHistories.Id)
from
LeaseFinances
INNER JOIN LeaseAssets ON LeaseFinances.id = LeaseAssets.LeaseFinanceId
INNER JOIN AssetValueHistories ON LeaseAssets.AssetId = AssetValueHistories.AssetId AND AssetValueHistories.IsLessorOwned = 1
Group by LeaseFinances.Id,LeaseAssets.AssetId
),
CTE_AssetCodeForLease
AS
(
Select
LeaseFinanceId
,ClassCode
,ClassCodeDescription
From
(
Select
LeaseFinanceId
,RankNumber =ROW_NUMBER () OVER ( PARTITION BY LeaseFinanceId ORDER BY LeaseFinanceId,AssetCost desc)
,ClassCode
,ClassCodeDescription
FROM
(
Select
LeaseFinanceId
,AssetCost = Sum(AssetValueHistories.NetValue_Amount)
,AssetClassCodes.ClassCode
,AssetClassCodes.Description AS ClassCodeDescription
From
CTE_AVHistory
INNER JOIN AssetValueHistories ON CTE_AVHistory.AssetValueHistoryId = AssetValueHistories.Id AND AssetValueHistories.IsLessorOwned = 1
INNER JOIN Assets ON CTE_AVHistory.AssetId = Assets.Id
INNER JOIN AssetTypes ON AssetTypes.Id=Assets.TypeId and AssetTypes.IsActive=1 AND AssetTypes.IsEligibleForFPI=1
INNER JOIN AssetClassCodes ON AssetClassCodes.Id=AssetTypes.AssetClassCodeId and AssetClassCodes.IsActive=1
GRoup by LeaseFinanceId,AssetClassCodes.ClassCode,AssetClassCodes.Description
) CCGroup
) FinalSelect where RankNumber = 1
),
CTE_AssetsForLease AS
(
SELECT
LeaseFinanceId
,AssetCost
,ClassCode
,ClassCodeDescription
,AssetId
FROM
(
Select
LeaseFinanceId=CTE_AssetCodeForLease.LeaseFinanceId
,AssetCost = AssetValueHistories.NetValue_Amount
,ClassCode=AssetClassCodes.ClassCode
,CTE_AssetCodeForLease.ClassCodeDescription
,AssetId=Assets.Id
,Rank=ROW_NUMBER () OVER ( PARTITION BY CTE_AssetCodeForLease.LeaseFinanceId ORDER BY AssetValueHistories.NetValue_Amount desc)
From
CTE_AVHistory
INNER JOIN AssetValueHistories ON CTE_AVHistory.AssetValueHistoryId = AssetValueHistories.Id AND CTE_AVHistory.AssetId=AssetValueHistories.AssetId AND AssetValueHistories.IsLessorOwned = 1
INNER JOIN Assets ON CTE_AVHistory.AssetId = Assets.Id
INNER JOIN AssetTypes ON AssetTypes.Id=Assets.TypeId and AssetTypes.IsActive=1 AND AssetTypes.IsEligibleForFPI=1
INNER JOIN AssetClassCodes ON AssetClassCodes.Id=AssetTypes.AssetClassCodeId and AssetClassCodes.IsActive=1
INNER JOIN CTE_AssetCodeForLease ON CTE_AssetCodeForLease.LeaseFinanceId=CTE_AVHistory.LeaseFinanceId AND CTE_AssetCodeForLease.ClassCode=AssetClassCodes.ClassCode
) Test WHERE Test.Rank=1
),
CTE_LoanAVHistory AS
(
Select
CollateralAssets.AssetId
,LoanFinanceId = LoanFinances.Id
,AssetValueHistoryId = Max(AssetValueHistories.Id)
from
LoanFinances
INNER JOIN CollateralAssets ON LoanFinances.id = CollateralAssets.LoanFinanceId
INNER JOIN AssetValueHistories ON CollateralAssets.AssetId = AssetValueHistories.AssetId
Group by LoanFinances.Id,CollateralAssets.AssetId
),
CTE_AssetCodeForLoan
AS
(
Select
LoanFinanceId
,ClassCode
,ClassCodeDescription
From
(
Select
LoanFinanceId
,RankNumber =ROW_NUMBER () OVER ( PARTITION BY LoanFinanceId ORDER BY LoanFinanceId,AssetCost desc)
,ClassCode
,ClassCodeDescription
FROM
(
Select
LoanFinanceId=CTE_LoanAVHistory.LoanFinanceId
,AssetCost = Sum(AssetValueHistories.NetValue_Amount)
,AssetClassCodes.ClassCode
,AssetClassCodes.Description AS ClassCodeDescription
From
CTE_LoanAVHistory
INNER JOIN AssetValueHistories ON CTE_LoanAVHistory.AssetValueHistoryId = AssetValueHistories.Id AND AssetValueHistories.IsLessorOwned = 1
INNER JOIN Assets ON CTE_LoanAVHistory.AssetId = Assets.Id
INNER JOIN AssetTypes ON AssetTypes.Id=Assets.TypeId and AssetTypes.IsActive=1 AND AssetTypes.IsEligibleForFPI=1
INNER JOIN AssetClassCodes ON AssetClassCodes.Id=AssetTypes.AssetClassCodeId and AssetClassCodes.IsActive=1
GRoup by CTE_LoanAVHistory.LoanFinanceId,AssetClassCodes.ClassCode,AssetClassCodes.Description
) CCGroup
) FinalSelect where RankNumber = 1
),
CTE_AssetsForLoan AS
(
SELECT
LoanFinanceId
,AssetCost
,ClassCode
,ClassCodeDescription
,AssetId
FROM
(
Select
LoanFinanceId=CTE_LoanAVHistory.LoanFinanceId
,AssetCost = AssetValueHistories.NetValue_Amount
,ClassCode=AssetClassCodes.ClassCode
,CTE_AssetCodeForLoan.ClassCodeDescription
,AssetId=Assets.Id
,Rank=ROW_NUMBER () OVER ( PARTITION BY CTE_AssetCodeForLoan.LoanFinanceId ORDER BY AssetValueHistories.NetValue_Amount desc)
From
CTE_LoanAVHistory
INNER JOIN AssetValueHistories ON CTE_LoanAVHistory.AssetValueHistoryId = AssetValueHistories.Id AND CTE_LoanAVHistory.AssetId=AssetValueHistories.AssetId AND AssetValueHistories.IsLessorOwned = 1
INNER JOIN Assets ON CTE_LoanAVHistory.AssetId = Assets.Id
INNER JOIN AssetTypes ON AssetTypes.Id=Assets.TypeId and AssetTypes.IsActive=1 AND AssetTypes.IsEligibleForFPI=1
INNER JOIN AssetClassCodes ON AssetClassCodes.Id=AssetTypes.AssetClassCodeId and AssetClassCodes.IsActive=1
INNER JOIN CTE_AssetCodeForLoan ON CTE_AssetCodeForLoan.LoanFinanceId=CTE_LoanAVHistory.LoanFinanceId AND CTE_AssetCodeForLoan.ClassCode=AssetClassCodes.ClassCode
) Test WHERE Test.Rank=1
),
EquipmentDescription as
(
SELECT ContractId=LeaseFinances.ContractId,AssetId,ClassCode,ClassCodeDescription,AssetCost FROM CTE_AssetsForLease
INNER JOIN LeaseFinances ON LeaseFinances.Id=CTE_AssetsForLease.LeaseFinanceId AND LeaseFinances.IsCurrent=1
union all
SELECT ContractId=LoanFinances.ContractId,AssetId,ClassCode,ClassCodeDescription,AssetCost FROM CTE_AssetsForLoan
INNER JOIN LoanFinances ON LoanFinances.Id=CTE_AssetsForLoan.LoanFinanceId AND LoanFinances.IsCurrent=1
)
Select ContractId,AssetId=AssetId,IsNULL(ClassCodeDescription,'')As AssetDescription,AssetClassCode=ClassCode
INTO #ContractEquipmentDescription
FROM
(
SELECT ContractId,AssetId,ClassCode,AssetCost,ClassCodeDescription
FROM EquipmentDescription
INNER JOIN Assets ON EquipmentDescription.AssetId=Assets.Id
INNER JOIN AssetTypes ON AssetTypes.Id=Assets.TypeId AND AssetTypes.IsActive=1 AND AssetTypes.IsEligibleForFPI=1
)
As ContractAssets
SELECT
ContractID
,NextInvoiceDate=CONVERT(NVARCHAR(10),Min(ReceivableDateDetails.DueDate),101),
RemainingInvoices=CONVERT(NVARCHAR(10),Count(ReceivableDateDetails.DueDate))
INTO #ContractReceivables
FROM
(
SELECT
DISTINCT Contracts.Id ContractID,
Receivables.DueDate
FROM Contracts
INNER JOIN LeaseFinances ON LeaseFinances.ContractId=Contracts.Id AND LeaseFinances.BookingStatus='Commenced'
INNER JOIN Receivables ON Receivables.EntityId=Contracts.Id AND Receivables.IsActive=1
INNER JOIN ReceivableDetails ON Receivables.Id=ReceivableDetails.ReceivableId
AND ReceivableDetails.BilledStatus = 'NotInvoiced' AND ReceivableDetails.IsActive=1
)  ReceivableDateDetails
GROUP BY
ReceivableDateDetails.ContractID
SELECT
*
INTO #CTE_PartyContacts
FROM
(
SELECT
PartyId=PartyContacts.PartyId,
PartyContactId=PartyContacts.Id,
PartyContactTypeId=PartyContactTypes.Id,
PartyFullName=PartyContacts.FullName,
UniqueIdentifier=PartyContacts.UniqueIdentifier,
PhoneNumber=PartyContacts.PhoneNumber1,
RANK=ROW_NUMBER() OVER(PARTITION BY PartyId ORDER BY PartyContacts.Id DESC)
FROM PartyContacts
INNER JOIN PartyContactTypes ON PartyContacts.Id=PartyContactTypes.PartyContactId
AND PartyContactTypes.ContactType='Main' AND PartyContacts.IsActive=1 AND PartyContactTypes.IsActive=1
)TEMP WHERE TEMP.RANK=1
SELECT
ContractID
,NextInvoiceDate=CONVERT(NVARCHAR,Min(ReceivableDateDetails.DueDate),101),
RemainingInvoices=CONVERT(NVARCHAR,Count(ReceivableDateDetails.DueDate))
INTO #ContractReceivablesForLoanFinances
FROM
(
SELECT
DISTINCT Contracts.Id ContractID,
Receivables.DueDate
FROM Contracts
INNER JOIN LoanFinances ON LoanFinances.ContractId=Contracts.Id AND LoanFinances.Status='Commenced'
INNER JOIN Receivables ON Receivables.EntityId=Contracts.Id AND Receivables.IsActive=1
INNER JOIN ReceivableDetails ON Receivables.Id=ReceivableDetails.ReceivableId
AND ReceivableDetails.BilledStatus = 'NotInvoiced' AND ReceivableDetails.IsActive=1
)  ReceivableDateDetails
GROUP BY
ReceivableDateDetails.ContractID
SELECT
ContractId,
AssetCost
INTO #ContractWithAssets
FROM
(
SELECT
ContractId=ContractId,
AssetCost=SUM(AcquisitionCost_Amount)
FROM
LoanFinances
INNER JOIN CollateralAssets ON LoanFinances.Id=CollateralAssets.LoanFinanceId AND IsCurrent=1 AND Status='Commenced' AND CollateralAssets.IsActive=1
INNER JOIN Assets ON Assets.Id=CollateralAssets.AssetId
INNER JOIN AssetTypes ON AssetTypes.Id=Assets.TypeId AND AssetTypes.IsEligibleForFPI=1
GROUP BY LoanFinances.ContractId
UNION ALL
SELECT
ContractId=ContractId,
AssetCost=SUM(LeaseAssets.NBV_Amount)
FROM
LeaseFinances
INNER JOIN LeaseAssets ON LeaseFinances.Id=LeaseAssets.LeaseFinanceId AND IsCurrent=1 AND BookingStatus='Commenced' AND LeaseAssets.IsActive=1
INNER JOIN Assets ON Assets.Id=LeaseAssets.AssetId
INNER JOIN AssetTypes ON AssetTypes.Id=Assets.TypeId AND AssetTypes.IsEligibleForFPI=1
GROUP BY LeaseFinances.ContractId
) AS ContractTemp
SELECT
AssetId,
LocationId
INTO #AssetLocationDetails
FROM
(
SELECT
AssetId,
LocationId,
AssetLocationOrder=ROW_NUMBER() OVER(Partition BY AssetId Order BY AssetLocations.Id DESC)
FROM AssetLocations WHERE IsActive=1 AND IsCurrent=1
) AS Temp_AssetLocationDetails WHERE AssetLocationOrder=1
SELECT ContractID
INTO #ContractWithSkippedPayments
FROM
(
SELECT
Count=COUNT(LeaseFinances.ContractId ),
ContractId=LeaseFinances.ContractId
FROM LeasePaymentSchedules
INNER JOIN LeaseFinances ON LeaseFinances.Id=LeasePaymentSchedules.LeaseFinanceDetailId AND LeaseFinances.IsCurrent=1
WHERE PaymentType='FixedTerm'
AND PaymentStructure!='InterestOnly'
AND Amount_Amount=0
AND LeaseFinances.SendToGAIC=1
AND LeaseFinances.GAICStatus='Queued'
GROUP BY LeaseFinances.ContractId
HAVING COUNT(LeaseFinances.ContractId )>0
UNION ALL
SELECT
Count=COUNT(LoanFinances.ContractId),
ContractId=LoanFinances.ContractId
FROM LoanPaymentSchedules
INNER JOIN LoanFinances ON LoanFinances.Id=LoanPaymentSchedules.LoanFinanceId AND LoanFinances.IsCurrent=1
WHERE PaymentType='FixedTerm'
AND PaymentStructure!='InterestOnly'
AND Amount_Amount=0
AND LoanFinances.IsSendToGAIC=1
AND LoanFinances.GAICStatus='Queued'
GROUP BY LoanFinances.ContractId
HAVING COUNT(LoanFinances.ContractId )>0
) AS Temp_ContractWithSkippedPayments
SELECT
*
INTO #ContractLoan
FROM
(
SELECT
CustomerNumber=Parties.PartyNumber,
LeaseNumber=Contracts.SequenceNumber
,LoanFinanceId=LoanFinances.Id,
EffectiveDate=CONVERT(NVARCHAR(10),LoanFinances.CommencementDate,101),
MaturityDate=CONVERT(NVARCHAR(10),LoanFinances.MaturityDate,101),
EquipmentValue=CONVERT(NVARCHAR(MAX),#ContractWithAssets.AssetCost),
LeaseFrequency=CAST(
CASE
WHEN LoanFinances.PaymentFrequency ='Yearly'
THEN 'A'
WHEN LoanFinances.PaymentFrequency ='Quarterly'
THEN 'Q'
WHEN LoanFinances.PaymentFrequency ='Monthly'
THEN 'M'
ELSE 'S'
END AS nvarchar),
NextInvoiceDate=#ContractReceivablesForLoanFinances.NextInvoiceDate,
RemainingInvoices=#ContractReceivablesForLoanFinances.RemainingInvoices,
PrebillDays=CASE WHEN ContractBillings.InvoiceLeadDays!=0 THEN ContractBillings.InvoiceLeadDays
ELSE Customers.InvoiceLeadDays
END,
RemitToName=RemitToes.Code,
AssetTypeName=#ContractEquipmentDescription.AssetClassCode,
AssetTypeDescription=#ContractEquipmentDescription.AssetDescription,
EquipmentAddress1=Locations.AddressLine1,
EquipmentLocationCity=Locations.City,
EquipmentLocationState=AssetState.LongName,
EquipmentLocationPostalCode=Locations.PostalCode,
BillToName=BillToes.Name,
BillToAddress1=PartyBillToAddress.AddressLine1,
BillToAddress2=PartyBillToAddress.AddressLine2,
BillToCity=PartyBillToAddress.City,
BillToState=PartyState.LongName,
BillToZip=PartyBillToAddress.PostalCode,
CustomerContactName=#CTE_PartyContacts.PartyFullName,
CustomerAddress1=PartyAddresses.AddressLine1,
CustomerAddress2=PartyAddresses.AddressLine2,
CustomerCity=PartyAddresses.City,
CustomerState=CustomerState.LongName,
CustomerPostal=PartyAddresses.PostalCode,
CustomerPhone=#CTE_PartyContacts.PhoneNumber,
CompanyCode='',
AddVIN=[dbo].GetContractAssetSerialNumber(Assets.Id,Contracts.Id),
VINNumber=ASN.SerialNumber,
ProcessFlag=CAST(
CASE
WHEN (LoanFinances.GAICStatus='Queued' OR ContractTerminations.TerminationDate!=null)
THEN '1'
ELSE '0'
END AS nvarchar),
ProcessSkipPaymentFlag=CAST(
CASE
WHEN (Contracts.Id=#ContractWithSkippedPayments.ContractId)
THEN '1'
ELSE '0'
END AS nvarchar),
ProcessACHFlag='1',
TerminationDate=ContractTerminations.TerminationDate
FROM Contracts
INNER JOIN LoanFinances ON LoanFinances.ContractId=Contracts.Id
AND LoanFinances.Status='Commenced' AND Contracts.Status='Commenced' AND LoanFinances.IsSendToGAIC=1
AND LoanFinances.IsCurrent=1
AND LoanFinances.GAICStatus='Queued'
INNER JOIN #ContractWithAssets ON Contracts.Id=#ContractWithAssets.ContractId
INNER JOIN Parties ON Parties.Id=LoanFinances.CustomerId
INNER JOIN Customers ON Customers.Id=Parties.Id AND Customers.Status='Active'
INNER JOIN BillToes ON BillToes.Id=Contracts.BillToId
AND BillToes.IsActive=1
INNER JOIN #ContractEquipmentDescription ON #ContractEquipmentDescription.ContractId=LoanFinances.ContractId
INNER JOIN CollateralAssets ON CollateralAssets.LoanFinanceId=LoanFinances.Id AND CollateralAssets.AssetId=#ContractEquipmentDescription.AssetId
AND CollateralAssets.IsActive=1
INNER JOIN Assets ON CollateralAssets.AssetId=Assets.Id
INNER JOIN AssetTypes ON AssetTypes.Id=Assets.TypeId
AND AssetTypes.IsActive=1
AND AssetTypes.IsEligibleForFPI=1
LEFT JOIN RemitToes ON RemitToes.Id=Contracts.RemitToId
LEFT JOIN #AssetLocationDetails ON #AssetLocationDetails.AssetId=Assets.Id
LEFT JOIN Locations ON #AssetLocationDetails.LocationId=Locations.Id
AND Locations.IsActive=1
LEFT JOIN States AS AssetState ON AssetState.Id=Locations.StateId
AND AssetState.IsActive=1
LEFT JOIN PartyAddresses AS PartyBillToAddress ON PartyBillToAddress.Id=BillToes.BillingAddressId
AND PartyBillToAddress.IsActive=1
LEFT JOIN States AS PartyState ON PartyState.Id=PartyBillToAddress.StateId
AND PartyState.IsActive=1
LEFT JOIN #CTE_PartyContacts ON Parties.Id=#CTE_PartyContacts.PartyId
LEFT JOIN PartyAddresses ON PartyAddresses.PartyId=Parties.Id
AND PartyAddresses.IsMain=1
AND PartyAddresses.IsActive=1
LEFT JOIN States AS CustomerState ON PartyAddresses.StateId=CustomerState.Id
LEFT JOIN #ContractReceivablesForLoanFinances ON Contracts.Id=#ContractReceivablesForLoanFinances.ContractID
LEFT JOIN ContractBillings ON Contracts.Id=ContractBillings.Id
LEFT JOIN ContractTerminations ON ContractTerminations.ContractId=Contracts.Id AND ContractTerminations.Status='Approved'
LEFT JOIN #ContractWithSkippedPayments ON #ContractWithSkippedPayments.ContractId=Contracts.Id
LEFT JOIN #AssetSerialNumbers ASN ON Assets.Id =  ASN.AssetId 
) AS ContractsForLoan
UPDATE LoanFinances Set GAICStatus='Sent',UpdatedTime=@UpdatedTime WHERE Id IN (SELECT LoanFinanceId FROM #ContractLoan)
SELECT *
INTO #ContractLease
FROM
(
SELECT
CustomerNumber=Parties.PartyNumber,
LeaseNumber=Contracts.SequenceNumber
,LeaseFinanceId=LeaseFinances.Id,
EffectiveDate=CONVERT(NVARCHAR(10),LeaseFinanceDetails.CommencementDate,101),
MaturityDate=CONVERT(NVARCHAR(10),LeaseFinanceDetails.MaturityDate,101),
LeaseFrequency=CAST(
CASE
WHEN LeaseFinanceDetails.PaymentFrequency ='Yearly'
THEN 'A'
WHEN LeaseFinanceDetails.PaymentFrequency ='Quarterly'
THEN 'Q'
WHEN LeaseFinanceDetails.PaymentFrequency ='Monthly'
THEN 'M'
ELSE 'S'
END AS nvarchar),
NextInvoiceDate=#ContractReceivables.NextInvoiceDate,
RemainingInvoices=#ContractReceivables.RemainingInvoices,
PrebillDays=CASE WHEN ContractBillings.InvoiceLeadDays!=0 THEN ContractBillings.InvoiceLeadDays
ELSE Customers.InvoiceLeadDays
END,
RemitToName=RemitToes.Code,
AssetTypeName=#ContractEquipmentDescription.AssetClassCode,
AssetTypeDescription=#ContractEquipmentDescription.AssetDescription,
EquipmentAddress1=Locations.AddressLine1,
EquipmentLocationCity=Locations.City,
EquipmentLocationState=AssetState.LongName,
EquipmentLocationPostalCode=Locations.PostalCode,
BillToName=BillToes.Name,
BillToAddress1=PartyBillToAddress.AddressLine1,
BillToAddress2=PartyBillToAddress.AddressLine2,
BillToCity=PartyBillToAddress.City,
BillToState=PartyState.LongName,
BillToZip=PartyBillToAddress.PostalCode,
CustomerContactName=#CTE_PartyContacts.PartyFullName,
CustomerAddress1=PartyAddresses.AddressLine1,
CustomerAddress2=PartyAddresses.AddressLine2,
CustomerCity=PartyAddresses.City,
CustomerState=CustomerState.LongName,
CustomerPostal=PartyAddresses.PostalCode,
CustomerPhone=#CTE_PartyContacts.PhoneNumber,
CompanyCode='',
AddVIN=[dbo].GetContractAssetSerialNumber(Assets.Id,Contracts.Id),
VINNumber=ASN.SerialNumber,
ProcessFlag=CAST(
CASE
WHEN (LeaseFinances.GAICStatus='Queued' OR ContractTerminations.TerminationDate!=null)
THEN '1'
ELSE '0'
END AS nvarchar),
ProcessSkipPaymentFlag=CAST(
CASE
WHEN (Contracts.Id=#ContractWithSkippedPayments.ContractId)
THEN '1'
ELSE '0'
END AS nvarchar),
ProcessACHFlag='1',
TerminationDate=ContractTerminations.TerminationDate
FROM Contracts
INNER JOIN LeaseFinances ON LeaseFinances.ContractId=Contracts.Id
AND LeaseFinances.BookingStatus='Commenced' AND Contracts.Status='Commenced' AND LeaseFinances.SendToGAIC=1
AND LeaseFinances.IsCurrent=1
AND LeaseFinances.GAICStatus='Queued'
INNER JOIN LeaseFinanceDetails ON LeaseFinanceDetails.Id=LeaseFinances.Id
INNER JOIN #ContractWithAssets ON Contracts.Id=#ContractWithAssets.ContractId
INNER JOIN Parties ON Parties.Id=LeaseFinances.CustomerId
INNER JOIN Customers ON Customers.Id=Parties.Id AND Customers.Status='Active'
INNER JOIN BillToes ON BillToes.Id=Contracts.BillToId
AND BillToes.IsActive=1
INNER JOIN #ContractEquipmentDescription ON #ContractEquipmentDescription.ContractId=LeaseFinances.ContractId
INNER JOIN LeaseAssets ON LeaseAssets.LeaseFinanceId=LeaseFinances.Id AND LeaseAssets.AssetId=#ContractEquipmentDescription.AssetId
AND LeaseAssets.IsActive=1
INNER JOIN Assets ON LeaseAssets.AssetId=Assets.Id
INNER JOIN AssetTypes ON AssetTypes.Id=Assets.TypeId
AND AssetTypes.IsActive=1
AND AssetTypes.IsEligibleForFPI=1
LEFT JOIN RemitToes ON RemitToes.Id=Contracts.RemitToId
LEFT JOIN #AssetLocationDetails ON #AssetLocationDetails.AssetId=Assets.Id
LEFT JOIN Locations ON #AssetLocationDetails.LocationId=Locations.Id
AND Locations.IsActive=1
LEFT JOIN States AS AssetState ON AssetState.Id=Locations.StateId
AND AssetState.IsActive=1
LEFT JOIN PartyAddresses AS PartyBillToAddress ON PartyBillToAddress.Id=BillToes.BillingAddressId
AND PartyBillToAddress.IsActive=1
LEFT JOIN States AS PartyState ON PartyState.Id=PartyBillToAddress.StateId
AND PartyState.IsActive=1
LEFT JOIN #CTE_PartyContacts ON Parties.Id=#CTE_PartyContacts.PartyId
LEFT JOIN PartyAddresses ON PartyAddresses.PartyId=Parties.Id
AND PartyAddresses.IsMain=1
AND PartyAddresses.IsActive=1
LEFT JOIN States AS CustomerState ON PartyAddresses.StateId=CustomerState.Id
LEFT JOIN #ContractReceivables ON Contracts.Id=#ContractReceivables.ContractID
LEFT JOIN ContractBillings ON Contracts.Id=ContractBillings.Id
LEFT JOIN ContractTerminations ON ContractTerminations.ContractId=Contracts.Id AND ContractTerminations.Status='Approved'
LEFT JOIN #ContractWithSkippedPayments ON #ContractWithSkippedPayments.ContractId=Contracts.Id
LEFT JOIN #AssetSerialNumbers ASN ON Assets.Id =  ASN.AssetId 
)AS ContractForLoan
UPDATE LeaseFinances Set GAICStatus='Sent',UpdatedTime=@UpdatedTime WHERE Id IN (SELECT LeaseFinanceId FROM #ContractLease)
SELECT
CustomerNumber,
LeaseNumber,
EffectiveDate,
MaturityDate,
LeaseFrequency,
NextInvoiceDate,
RemainingInvoices,
PrebillDays,
RemitToName,
AssetTypeName,
AssetTypeDescription,
EquipmentAddress1,
EquipmentLocationCity,
EquipmentLocationState,
EquipmentLocationPostalCode,
BillToName,
BillToAddress1,
BillToAddress2,
BillToCity,
BillToState,
BillToZip,
CustomerContactName,
CustomerAddress1,
CustomerAddress2,
CustomerCity,
CustomerState,
CustomerPostal,
CustomerPhone,
CompanyCode,
AddVIN,
VINNumber,
ProcessFlag,
TerminationDate,
ProcessSkipPaymentFlag,
ProcessACHFlag
FROM
#ContractLoan
UNION ALL
SELECT
CustomerNumber,
LeaseNumber,
EffectiveDate,
MaturityDate,
LeaseFrequency,
NextInvoiceDate,
RemainingInvoices,
PrebillDays,
RemitToName,
AssetTypeName,
AssetTypeDescription,
EquipmentAddress1,
EquipmentLocationCity,
EquipmentLocationState,
EquipmentLocationPostalCode,
BillToName,
BillToAddress1,
BillToAddress2,
BillToCity,
BillToState,
BillToZip,
CustomerContactName,
CustomerAddress1,
CustomerAddress2,
CustomerCity,
CustomerState,
CustomerPostal,
CustomerPhone,
CompanyCode,
AddVIN,
VINNumber,
ProcessFlag,
TerminationDate,
ProcessSkipPaymentFlag,
ProcessACHFlag
FROM
#ContractLease
DROP TABLE #ContractEquipmentDescription
DROP TABLE #ContractReceivables
DROP TABLE #CTE_PartyContacts
DROP TABLE #ContractReceivablesForLoanFinances
DROP TABLE #ContractLoan
DROP TABLE #ContractLease
DROP TABLE #ContractWithAssets
DROP TABLE #AssetLocationDetails
DROP Table #ContractWithSkippedPayments
END

GO
