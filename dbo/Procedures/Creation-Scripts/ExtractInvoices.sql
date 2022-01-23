SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ExtractInvoices]
(
@JobInstanceId BIGINT,
@CreatedById BIGINT,
@CustomerDetails CustomerDetails READONLY,
@CreatedTime DATETIMEOFFSET,
@BillNegativeandZeroReceivables BIT
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
--DECLARE @CustomerId BIGINT;
--DECLARE @JobInstanceId BIGINT;
--DECLARE @CreatedById BIGINT;
--DECLARE @CustomerDetails CustomerDetails
--SET @CustomerId = 4235;
--SET @JobInstanceId = 31;
--SET @CreatedById = 1;
SELECT * INTO #CustomerDetails FROM (SELECT * FROM @CustomerDetails CustomerDetails) AS cusdet
CREATE TABLE #InvoiceIdList
(
InvoiceId BIGINT NOT NULL PRIMARY KEY CLUSTERED
);
CREATE TABLE #CTE_BillToDetails
(
AttributeName NVARCHAR(MAX),
InvoiceId BIGINT
);
CREATE TABLE #ReceivableAsset
(
InvoiceID BIGINT,
ReceivableInvoiceDetailId BIGINT,
ReceivableDetailID BIGINT,
AssetId BIGINT,
AssetAddressLine1 NVARCHAR(50),
AssetAddressLine2 NVARCHAR(50),
AssetCity NVARCHAR(40),
AssetState NVARCHAR(5),
AssetDivision NVARCHAR(40),
AssetCountry NVARCHAR(5),
AssetPostalCode NVARCHAR(12),
AssetPurchaseOrderNumber NVARCHAR(40),
AssetSerialNumber NVARCHAR(100),
AssetDescription NVARCHAR(500),
u_CustomerReference1 NVARCHAR(100),
u_CustomerReference2 NVARCHAR(100),
u_CustomerReference3 NVARCHAR(100),
u_CustomerReference4 NVARCHAR(100),
u_CustomerReference5 NVARCHAR(100)
);
CREATE NONCLUSTERED INDEX [IX_ReceivableAsset_InvoiceId_RecDetailId]
ON [dbo].[#ReceivableAsset] ([InvoiceID],[ReceivableInvoiceDetailId],[ReceivableDetailID])
INCLUDE ([AssetId],[AssetAddressLine1],[AssetAddressLine2],[AssetCity],[AssetState],[AssetDivision],[AssetCountry],[AssetPostalCode],
[AssetPurchaseOrderNumber],[AssetSerialNumber],[AssetDescription],[u_CustomerReference1],[u_CustomerReference2],[u_CustomerReference3],
[u_CustomerReference4],[u_CustomerReference5]);
CREATE TABLE #ReceivableTaxHeader
(
InvoiceId BIGINT,
ReceivableTaxDetailId BIGINT NOT NULL,
ReceivableDetailId BIGINT,
AssetId BIGINT,
ReceivableCodeId BIGINT,
ReceivableTaxImpositionId BIGINT
);
CREATE TABLE #BillToDetails
(
Id BIGINT,
BillingAddressId BIGINT,
BillingContactPersonId BIGINT,
DeliverInvoiceViaEmail BIT,
AssetGroupByOption BIT,
UseDynamicContentForInvoiceAddendumBody BIT,
GenerateInvoiceAddendum BIT,
InvoiceNumberLabel NVARCHAR(38),
InvoiceDateLabel NVARCHAR(34),
CustomerBillToName NVARCHAR(500),
ReportName NVARCHAR(200),
InvoiceType NVARCHAR(200),
ReportFormatId BIGINT
);
--DECLARE @BillNegativeandZeroReceivables BIT =
--(SELECT VALUE FROM GlobalParameters
--WHERE Category = 'Invoicing'
--	AND Name = 'BillNegativeandZeroReceivables')
INSERT INTO #InvoiceIdList (InvoiceId)
SELECT Id FROM dbo.ReceivableInvoices
INNER JOIN #CustomerDetails ON (#CustomerDetails.CustomerId = ReceivableInvoices.CustomerId
AND #CustomerDetails.LegalEntityId = ReceivableInvoices.LegalEntityId
AND JobStepInstanceId = @JobInstanceId
AND StatementInvoicePreference IN('GenerateAndDeliver','SuppressDelivery'))
AND ((@BillNegativeandZeroReceivables = 0 AND (InvoiceAmount_Amount > 0 OR InvoiceTaxAmount_Amount > 0 OR Balance_Amount > 0 OR TaxBalance_Amount > 0))
OR @BillNegativeandZeroReceivables = 1)
INSERT INTO #CTE_BillToDetails(AttributeName,InvoiceId)
SELECT agbo.AttributeName,ri.Id
FROM dbo.BillToes bt
JOIN dbo.BillToAssetGroupByOptions btagbo
ON bt.Id = btagbo.BillToId
JOIN dbo.AssetGroupByOptions agbo
ON btagbo.AssetGroupByOptionId = agbo.Id
JOIN dbo.ReceivableInvoices ri WITH(NOLOCK)
ON bt.Id = ri.BillToId
JOIN dbo.#InvoiceIdList ON #InvoiceIdList.InvoiceId = ri.Id
WHERE btagbo.IsActive = 1
AND btagbo.IncludeInInvoice = 1
INSERT INTO #BillToDetails
SELECT bt.Id, bt.BillingAddressId, bt.BillingContactPersonId, bt.DeliverInvoiceViaEmail, bt.AssetGroupByOption, bt.UseDynamicContentForInvoiceAddendumBody, 
bt.GenerateInvoiceAddendum, bt.InvoiceNumberLabel, bt.InvoiceDateLabel, bt.CustomerBillToName, ifo.ReportName, itl.Name,ri.ReportFormatId
FROM dbo.ReceivableInvoices ri
INNER JOIN #InvoiceIdList ON #InvoiceIdList.InvoiceId = ri.Id
INNER JOIN dbo.BillToes bt on ri.BillToId = bt.Id
INNER JOIN dbo.InvoiceFormats ifo ON ri.ReportFormatId = ifo.Id
INNER JOIN dbo.BillToInvoiceFormats bif ON bt.Id = bif.BillToId
INNER JOIN dbo.InvoiceTypeLabelConfigs itl ON bif.InvoiceTypeLabelId = itl.Id
INNER JOIN dbo.InvoiceTypes it ON itl.InvoiceTypeId = it.Id AND ifo.InvoiceTypeId = it.Id
WHERE ri.IsActive = 1 AND ri.IsStatementInvoice = 0
UNION ALL
SELECT bt.Id, bt.BillingAddressId, bt.BillingContactPersonId, bt.DeliverInvoiceViaEmail, bt.AssetGroupByOption, bt.UseDynamicContentForInvoiceAddendumBody, 
bt.GenerateInvoiceAddendum, bt.InvoiceNumberLabel, bt.InvoiceDateLabel, bt.CustomerBillToName, ifo.ReportName, NULL, ri.ReportFormatId
FROM dbo.ReceivableInvoices ri
INNER JOIN #InvoiceIdList ON #InvoiceIdList.InvoiceId = ri.Id
INNER JOIN dbo.BillToes bt on ri.BillToId = bt.Id 
INNER JOIN dbo.InvoiceFormats ifo ON ri.ReportFormatId = ifo.Id
WHERE ri.IsActive = 1 AND ri.IsStatementInvoice = 1
INSERT INTO InvoiceExtractCustomerDetails
(InvoiceID,InvoiceType,InvoiceNumber,InvoiceRunDate,DueDate,BillToId,CustomerName,CustomerNumber,AttentionLine,TotalReceivableAmount_Amount,TotalReceivableAmount_Currency,TotalTaxAmount_Amount,TotalTaxAmount_Currency
,RemitToName,LegalEntityNumber,LegalEntityName,IsACH,RemitToCode,InvoiceNumberLabel,InvoiceRunDateLabel,BillingAddressLine1,BillingAddressLine2,BillingCity,BillingState
,BillingZip,BillingCountry,ReportFormatName,GSTId,LogoId,LessorAddressLine1,LessorAddressLine2,LessorCity,LessorState,LessorZip,
LessorCountry,LessorContactPhone,LessorContactEmail,LessorWebAddress,CustomerComments,CustomerInvoiceCommentBeginDate,CustomerInvoiceCommentEndDate,GenerateInvoiceAddendum,AttributeName,UseDynamicContentForInvoiceAddendumBody,GroupAssets,DeliverInvoiceViaEmail,OCRMCR
,CreatedById,CreatedTime,JobStepInstanceId)
SELECT DISTINCT
ri.Id [InvoiceID],
bt.InvoiceType [InvoiceType],
ri.Number [InvoiceNumber],
ri.InvoiceRunDate [InvoiceRunDate],
ri.DueDate [DueDate],
ri.BillToId,
bt.CustomerBillToName [CustomerName],
p.PartyNumber [CustomerNumber],
CASE WHEN bt.BillingContactPersonId IS NOT NULL THEN 'ATTN: ' + pc2.FullName
ELSE '' END [AttentionLine],
ri.InvoiceAmount_Amount,
ri.InvoiceAmount_Currency,
ri.InvoiceTaxAmount_Amount,
ri.InvoiceTaxAmount_Currency,
rt.Name [RemitToName],
le.LegalEntityNumber,
le.Name [LegalEntityName],
ri.IsACH [IsACH],
rt.Code [RemitToCode],
CASE WHEN bt.InvoiceNumberLabel = 'InvoiceNumber' THEN 'Invoice Number'
WHEN bt.InvoiceNumberLabel = 'PaymentAdviceNumber' THEN 'Payment Advice Number'
WHEN bt.InvoiceNumberLabel = 'NoticeNumber' THEN 'Notice Number'
WHEN bt.InvoiceNumberLabel = 'BillNumber' THEN 'Bill Number'
ELSE bt.InvoiceNumberLabel
END [InvoiceNumberLabel],
CASE WHEN bt.InvoiceDateLabel = 'InvoiceDate' THEN 'Invoice Date'
WHEN bt.InvoiceDateLabel = 'PaymentAdviceDate' THEN 'Payment Advice Date'
WHEN bt.InvoiceDateLabel = 'NoticeDate' THEN 'Notice Date'
WHEN bt.InvoiceDateLabel = 'BillDate' THEN 'Bill Date'
ELSE bt.InvoiceDateLabel
END [InvoiceRunDateLabel],
pa.AddressLine1 [BillingAddressLine1],
pa.AddressLine2 [BillingAddressLine2],
pa.City [BillingCity],
ISNULL(billingState.ShortName,billingHomeState.ShortName) [BillingState],
pa.PostalCode [BillingZip],
ISNULL(billingCountry.ShortName,billingHomeCountry.ShortName) [BillingCountry],
bt.ReportName [ReportFormatName],
le.GSTId,
rt.LogoId,
ISNULL(lea.AddressLine1,pa2.AddressLine1) [LessorAddressLine1],
ISNULL(lea.AddressLine2,pa2.AddressLine2) [LessorAddressLine2],
ISNULL(lea.City,pa2.City) [LessorCity],
ISNULL(legalEntityState.ShortName,partyState.ShortName) [LessorState],
ISNULL(lea.PostalCode,pa2.PostalCode) [LessorZip],
ISNULL(legalEntityCountry.ShortName,partyCountry.ShortName) [LessorCountry],
REPLACE(REPLACE(ISNULL(lec.PhoneNumber1,pc.PhoneNumber1),'-',''),' ','') [LessorContactPhone],
ISNULL(lec.EMailId,pc.EMailId) [LessorContactEmail],
le.LessorWebAddress [LessorWebAddress],
SUBSTRING(cus.InvoiceComment ,1, 200) [CustomerComments],
cus.InvoiceCommentBeginDate [CustomerInvoiceCommentBeginDate],
cus.InvoiceCommentEndDate [CustomerInvoiceCommentEndDate],
bt.GenerateInvoiceAddendum [GenerateInvoiceAddendum],
cbtd.AttributeName [AttributeName],
bt.UseDynamicContentForInvoiceAddendumBody [UseDynamicContentForInvoiceAddendumBody],
bt.AssetGroupByOption,
bt.DeliverInvoiceViaEmail,
/*This OCRMCR will work only for invoices with single contract. The customer level OCRMCR is handled in the respective SPs*/
--RIGHT('00000000000'+ CONVERT(VARCHAR,dbo.GetOCRCodes(le.LegalEntityNumber)),12) +' '+ RIGHT('000000000'+ CONVERT(VARCHAR,p.PartyNumber),10) +' '+
--RIGHT('000000000000000000000000000'+ CONVERT(VARCHAR,dbo.GetOCRCodes(cd.SequenceNumber)),28)  +' '+  RIGHT('000000000'+ CONVERT(VARCHAR,ri.Number),10)+' ' +
--RIGHT('000000000'+ CONVERT(VARCHAR,(REPLACE((ri.InvoiceAmount_Amount + ri.InvoiceTaxAmount_Amount ),'.',''))),10) +' '+
--RIGHT('0000000'+ CONVERT(VARCHAR,(REPLACE(CONVERT(VARCHAR(10),ri.DueDate,101),'/',''))),8) [OCRMCR],
NULL [OCRMCR],
@CreatedById,
@CreatedTime,
@JobInstanceId
FROM
dbo.ReceivableInvoices ri
INNER JOIN #InvoiceIdList ON #InvoiceIdList.InvoiceId = ri.Id
INNER JOIN #BillToDetails bt ON ri.BillToId = bt.Id and ri.ReportFormatId = bt.ReportFormatId
--INNER JOIN dbo.ReceivableCategories rc ON rc.Id = ri.ReceivableCategoryId
--	AND bif.ReceivableCategory = rc.Name
INNER JOIN dbo.RemitToes rt ON ri.RemitToId = rt.Id AND rt.IsActive = 1
--LEFT JOIN dbo.Logoes logo ON logo.Id = rt.LogoId
INNER JOIN dbo.PartyAddresses pa ON bt.BillingAddressId = pa.Id
LEFT JOIN dbo.States billingState ON pa.StateId = billingState.Id
LEFT JOIN dbo.Countries billingCountry ON billingState.CountryId = billingCountry.Id
LEFT JOIN dbo.States billingHomeState ON pa.StateId = billingHomeState.Id
LEFT JOIN dbo.Countries billingHomeCountry ON billingHomeState.CountryId = billingHomeCountry.Id
INNER JOIN dbo.LegalEntities le ON ri.LegalEntityId = le.Id
INNER JOIN dbo.Customers cus ON ri.CustomerId = cus.Id
INNER JOIN dbo.Parties p ON cus.Id = p.Id
LEFT JOIN dbo.PartyContacts pc2 ON bt.BillingContactPersonId = pc2.Id
LEFT JOIN dbo.LegalEntityAddresses lea ON rt.LegalEntityAddressId = lea.Id
LEFT JOIN dbo.States legalEntityState ON lea.StateId = legalEntityState.Id
LEFT JOIN Countries legalEntityCountry ON legalEntityState.CountryId = legalEntityCountry.Id
LEFT JOIN dbo.LegalEntityContacts lec ON rt.LegalEntityContactId = lec.Id
LEFT JOIN dbo.PartyAddresses pa2 ON rt.PartyAddressId = pa2.Id
LEFT JOIN dbo.States partyState ON pa2.StateId = partyState.Id
LEFT JOIN Countries partyCountry ON partyState.CountryId = partyCountry.Id
LEFT JOIN dbo.PartyContacts pc ON rt.PartyContactId = pc.Id
LEFT JOIN #CTE_BillToDetails cbtd ON cbtd.InvoiceId = ri.Id
WHERE ri.IsActive = 1
--UPDATE InvoiceExtractCustomerDetails SET OCRMCR = OCRMCR + ' ' + dbo.GetOCRCheckDigitValue(OCRMCR)
--FROM InvoiceExtractCustomerDetails
--JOIN #InvoiceIdList ON InvoiceExtractCustomerDetails.InvoiceId = #InvoiceIdList.InvoiceId
INSERT INTO #ReceivableAsset
(InvoiceID,ReceivableInvoiceDetailId,ReceivableDetailID,AssetId,AssetAddressLine1,AssetAddressLine2,AssetCity,AssetState,AssetDivision,AssetCountry,AssetPostalCode,AssetPurchaseOrderNumber,
AssetSerialNumber,AssetDescription,u_CustomerReference1,u_CustomerReference2,u_CustomerReference3,u_CustomerReference4,u_CustomerReference5)
SELECT
ri.Id [InvoiceID],
rid.Id [ReceivableInvoiceDetailId],
rd.Id [ReceivableDetailId],
assets.Id [AssetId],
Locations.AddressLine1 [AssetAddressLine1],
Locations.AddressLine2 [AssetAddressLine2],
Locations.City [AssetCity],
States.ShortName [AssetState],
Locations.Division [AssetDivision],
Countries.ShortName [AssetCountry],
Locations.PostalCode [AssetPostalCode],
assets.CustomerPurchaseOrderNumber [AssetPurchaseOrderNumber],
assets.SerialNumber [AssetSerialNumber],
assets.Description [AssetDescription],
NULL [u_CustomerReference1],
NULL [u_CustomerReference2],
NULL [u_CustomerReference3],
NULL [u_CustomerReference4],
NULL [u_CustomerReference5]
FROM
dbo.ReceivableInvoices ri
INNER JOIN #InvoiceIdList ON #InvoiceIdList.InvoiceId = ri.Id
INNER JOIN dbo.ReceivableInvoiceDetails rid ON ri.Id = rid.ReceivableInvoiceId AND rid.IsActive = 1
INNER JOIN dbo.ReceivableDetails rd ON rid.ReceivableDetailId = rd.Id
INNER JOIN dbo.Assets assets ON rd.AssetId = assets.Id
INNER JOIN dbo.ReceivableTaxDetails rtd ON rd.Id = rtd.ReceivableDetailId AND rtd.AssetId = rd.AssetId AND rtd.IsActive = 1
INNER JOIN dbo.Locations ON rtd.LocationId = Locations.Id
INNER JOIN dbo.States ON Locations.StateId = States.Id
INNER JOIN dbo.Countries ON States.CountryId = Countries.Id
WHERE ri.IsActive = 1
Union All
SELECT
ri.Id [InvoiceID],
rid.Id [ReceivableInvoiceDetailId],
rd.Id [ReceivableDetailId],
NULL [AssetId],
Locations.AddressLine1 [AssetAddressLine1],
Locations.AddressLine2 [AssetAddressLine2],
Locations.City [AssetCity],
States.ShortName [AssetState],
Locations.Division [AssetDivision],
Countries.ShortName [AssetCountry],
Locations.PostalCode [AssetPostalCode],
NULL [AssetPurchaseOrderNumber],
NULL [AssetSerialNumber],
NULL [AssetDescription],
NULL [u_CustomerReference1],
NULL [u_CustomerReference2],
NULL [u_CustomerReference3],
NULL [u_CustomerReference4],
NULL [u_CustomerReference5]
FROM
dbo.ReceivableInvoices ri
INNER JOIN #InvoiceIdList ON #InvoiceIdList.InvoiceId = ri.Id
INNER JOIN dbo.ReceivableInvoiceDetails rid ON ri.Id = rid.ReceivableInvoiceId AND rid.IsActive = 1
INNER JOIN dbo.ReceivableDetails rd ON rid.ReceivableDetailId = rd.Id
INNER JOIN dbo.ReceivableTaxDetails rtd ON rd.Id = rtd.ReceivableDetailId AND rtd.IsActive = 1
INNER JOIN dbo.Locations ON rtd.LocationId = Locations.Id
INNER JOIN dbo.States ON Locations.StateId = States.Id
INNER JOIN dbo.Countries ON States.CountryId = Countries.Id
INNER JOIN dbo.Contracts ON  rid.EntityId = Contracts.Id AND rid.EntityType = 'CT'
WHERE ri.IsActive = 1 AND Contracts.ContractType = 'Loan'
SELECT ri.Id [InvoiceId],conhis.SequenceNumber [SequenceNumber], ROW_NUMBER() OVER(PARTITION BY [InvoiceId] ORDER BY conhis.Id) RowNumber
INTO #AssumedContractDetails
FROM ReceivableInvoices ri
INNER JOIN #InvoiceIdList ON #InvoiceIdList.InvoiceId = ri.Id
JOIN ReceivableInvoiceDetails rid ON ri.Id = rid.ReceivableInvoiceId
JOIN ReceivableDetails rd ON rid.ReceivableDetailId = rd.Id
AND rd.IsActive = 1
JOIN Receivables r ON rd.ReceivableId = r.Id
AND r.IsActive = 1
JOIN Contracts con ON con.Id = r.EntityId
AND r.EntityType = 'CT'
JOIN ContractAssumptionHistories conhis ON conhis.ContractId = con.Id
AND conhis.IsActive = 1
JOIN Assumptions ON conhis.AssumptionId = Assumptions.Id
LEFT JOIN LeasePaymentSchedules ON Assumptions.LeasePaymentId = LeasePaymentSchedules.Id
LEFT JOIN LoanPaymentSchedules ON Assumptions.LoanPaymentId = LoanPaymentSchedules.Id
WHERE (LeasePaymentSchedules.Id IS NOT NULL AND r.DueDate < LeasePaymentSchedules.DueDate)
OR  r.DueDate < LoanPaymentSchedules.DueDate
SELECT DISTINCT
ri.Id [InvoiceId],
rid.EntityType [EntityType],
CASE WHEN rid.EntityType = 'CT' THEN ISNULL(Assumption.SequenceNumber,c.SequenceNumber)
WHEN rid.EntityType = 'DT' THEN Discountings.SequenceNumber
ELSE NULL END [SequenceNumber],
CASE WHEN rid.EntityType = 'CT' THEN c.Id
WHEN rid.EntityType = 'DT' THEN Discountings.Id
ELSE ri.CustomerId END [EntityId],
CASE WHEN (rid.EntityType = 'CT' AND c.ContractType = 'Lease') THEN leasefin2.MaturityDate
WHEN (rid.EntityType = 'CT' AND (c.ContractType = 'Loan' OR c.ContractType = 'ProgressLoan')) THEN loanfin.MaturityDate
WHEN rid.EntityType = 'DT' THEN DiscountingFinances.MaturityDate
ELSE NULL END [MaturityDate],
ISNULL(leasefin.PurchaseOrderNumber,loanfin.ContractPurchaseOrderNumber) [ContractPurchaseOrderNumber]
INTO #ContractDetails
FROM
dbo.ReceivableInvoices ri
INNER JOIN #InvoiceIdList ON #InvoiceIdList.InvoiceId = ri.Id
INNER JOIN dbo.ReceivableInvoiceDetails rid WITH(NOLOCK) ON ri.Id = rid.ReceivableInvoiceId
LEFT JOIN dbo.Contracts c ON rid.EntityId = c.Id AND rid.EntityType = 'CT'
LEFT JOIN dbo.LoanFinances loanfin ON loanfin.ContractId = c.Id AND loanfin.IsCurrent = 1
LEFT JOIN dbo.LeaseFinances leasefin ON leasefin.ContractId = c.Id AND leasefin.IsCurrent = 1
LEFT JOIN dbo.LeaseFinanceDetails leasefin2 ON leasefin.Id = leasefin2.Id
LEFT JOIN dbo.Discountings ON rid.EntityId = Discountings.Id AND rid.EntityType = 'DT'
LEFT JOIN dbo.DiscountingFinances ON DiscountingFinances.DiscountingId = Discountings.Id AND DiscountingFinances.IsCurrent = 1
LEFT JOIN #AssumedContractDetails Assumption ON Assumption.InvoiceId = ri.Id AND Assumption.RowNumber = 1
INSERT INTO InvoiceExtractReceivableDetails
(InvoiceID,ReceivableInvoiceDetailId,ReceivableDetailID,BlendNumber,ReceivableAmount_Amount,ReceivableAmount_Currency,TaxAmount_Amount,TaxAmount_Currency,PeriodStartDate,PeriodEndDate,ReceivableCategoryId,ReceivableCodeId,
AssetId,AssetAddressLine1,AssetAddressLine2,AssetCity,AssetState,AssetDivision,AssetCountry,AssetPostalCode,AssetPurchaseOrderNumber,AssetSerialNumber,AssetDescription,u_CustomerReference1,
u_CustomerReference2,u_CustomerReference3,u_CustomerReference4,u_CustomerReference5,CreatedById,CreatedTime,EntityType,SequenceNumber,EntityId,MaturityDate,
ContractPurchaseOrderNumber,AdditionalComments,AdditionalInvoiceCommentBeginDate,AdditionalInvoiceCommentEndDate,ExchangeRate,AlternateBillingCurrencyCodeId,
WithHoldingTax_Amount, WithHoldingTax_Currency)
SELECT
ri.Id [InvoiceID],
rid.Id [ReceivableInvoiceDetailId],
rd.Id [ReceivableDetailId],
rid.BlendNumber,
rid.InvoiceAmount_Amount,
rid.InvoiceAmount_Currency,
rid.InvoiceTaxAmount_Amount,
rid.InvoiceTaxAmount_Currency,
CASE
WHEN (r.SourceTable ='CPUSchedule') THEN lps3.StartDate
WHEN ( c.ContractType = 'Lease') THEN lps.StartDate
WHEN c.ContractType = 'Loan' THEN lps2.StartDate
ELSE NULL
END [PeriodStartDate],
CASE
WHEN r.SourceTable = 'CPUSchedule' THEN lps3.EndDate
WHEN (c.ContractType = 'Lease') THEN lps.EndDate
WHEN c.ContractType = 'Loan' THEN lps2.EndDate
ELSE NULL
END [PeriodEndDate],
rcategory.Id [ReceivableCategoryId],
rcode.Id [ReceivableCodeId],
ra.AssetId,
AssetAddressLine1,
AssetAddressLine2,
AssetCity,
AssetState,
AssetDivision,
AssetCountry,
AssetPostalCode,
AssetPurchaseOrderNumber,
AssetSerialNumber,
AssetDescription,
u_CustomerReference1,
u_CustomerReference2,
u_CustomerReference3,
u_CustomerReference4,
u_CustomerReference5,
@CreatedById,
@CreatedTime,
cd.EntityType EntityType,
cd.SequenceNumber,
cd.EntityId,
MaturityDate,
ContractPurchaseOrderNumber,
SUBSTRING(cb.InvoiceComment ,1, 200) [AdditionalComments],
cb.InvoiceCommentBeginDate [AdditionalInvoiceCommentBeginDate],
cb.InvoiceCommentEndDate [AdditionalInvoiceCommentEndDate],
rid.ExchangeRate [ExchangeRate],
CurrencyCodes.Id [AlternateBillingCurrencyCodeId],
ISNULL(rdwtd.Tax_Amount, 0),
ISNULL(rdwtd.Tax_Currency, rid.InvoiceAmount_Currency)
FROM
dbo.ReceivableInvoices ri
INNER JOIN #InvoiceIdList ON #InvoiceIdList.InvoiceId = ri.Id
INNER JOIN dbo.ReceivableInvoiceDetails rid ON ri.Id = rid.ReceivableInvoiceId
INNER JOIN dbo.ReceivableDetails rd ON rid.ReceivableDetailId = rd.Id
INNER JOIN dbo.Receivables r ON r.Id = rd.ReceivableId
INNER JOIN dbo.ReceivableCodes rcode ON rcode.Id = r.ReceivableCodeId
INNER JOIN dbo.ReceivableCategories rcategory ON rcode.ReceivableCategoryId = rcategory.Id
INNER JOIN #ContractDetails cd ON cd.InvoiceId = ri.Id AND cd.EntityType = rid.EntityType
AND rid.EntityId = cd.EntityId
INNER JOIN Currencies ON Currencies.Id = ri.AlternateBillingCurrencyId
INNER JOIN CurrencyCodes ON CurrencyCodes.Id = Currencies.CurrencyCodeId And CurrencyCodes.IsActive = 1
LEFT JOIN dbo.Contracts c ON rid.EntityId = c.Id AND rid.EntityType = 'CT'
LEFT JOIN dbo.ContractBillings cb ON cb.Id = c.Id AND cb.IsActive = 1
LEFT JOIN dbo.LeasePaymentSchedules lps ON r.PaymentScheduleId = lps.Id AND lps.IsActive = 1 AND r.SourceTable = '_'
LEFT JOIN dbo.LoanPaymentSchedules lps2 ON r.PaymentScheduleId = lps2.Id AND lps2.IsActive = 1 AND r.SourceTable = '_'
LEFT JOIN dbo.CPUPaymentSchedules lps3 ON r.PaymentScheduleId = lps3.Id AND lps3.IsActive = 1 AND  r.SourceTable = 'CPUSchedule'
LEFT JOIN #ReceivableAsset ra ON ra.InvoiceID = rid.ReceivableInvoiceId
AND ra.ReceivableInvoiceDetailId = rid.Id
AND ra.ReceivableDetailID = rid.ReceivableDetailId
LEFT JOIN dbo.ReceivableDetailsWithholdingTaxDetails rdwtd ON rdwtd.ReceivableDetailId = rd.Id AND rdwtd.IsActive = 1
WHERE ri.IsActive = 1
INSERT INTO #ReceivableTaxHeader(InvoiceId,ReceivableTaxDetailId,ReceivableDetailId,AssetId,ReceivableCodeId, ReceivableTaxImpositionId)
SELECT DISTINCT ri.InvoiceId [InvoiceId],rtd.Id [ReceivableTaxDetailId],rd.id [ReceivableDetailId],rtd.AssetId,r.ReceivableCodeId,  rti.Id
FROM #InvoiceIdList ri
INNER JOIN dbo.ReceivableInvoiceDetails rid  ON ri.InvoiceId = rid.ReceivableInvoiceId
INNER JOIN dbo.ReceivableDetails rd  ON rid.ReceivableDetailId = rd.id
INNER JOIN Receivables r ON r.id = rd.ReceivableId
INNER JOIN ReceivableTaxes rt ON rt.ReceivableId = r.Id AND rt.IsActive = 1
INNER JOIN dbo.ReceivableTaxDetails rtd ON rtd.ReceivableDetailId = rd.Id AND rtd.IsActive = 1 AND rtd.ReceivableTaxId = rt.Id
INNER JOIN ReceivableTaxImpositions rti ON rtd.Id = rti.ReceivableTaxDetailId And rti.IsActive = 1
Create Index IX_ReceivableTaxImpositionId On #ReceivableTaxHeader (ReceivableTaxImpositionId) Include (InvoiceId,ReceivableDetailId,AssetId, ReceivableCodeId, ReceivableTaxDetailId)
INSERT INTO dbo.InvoiceExtractReceivableTaxDetails
(InvoiceID,TaxTypeId,ReceivableDetailId,ReceivableTaxDetailId,AssetId,Rent_Amount,Rent_Currency,TaxAmount_Amount,TaxAmount_Currency,ExternalJurisdictionId
,ImpositionType,ReceivableCodeId,CreatedById,CreatedTime)
SELECT
rth.InvoiceId [InvoiceId],
rti.TaxTypeId [TaxTypeId],
rth.ReceivableDetailId [ReceivableDetailId],
rth.ReceivableTaxDetailId [ReceivableTaxDetailId],
rth.AssetId [AssetId],
rti.TaxableBasisAmount_Amount [Rent_Amount],
rti.TaxableBasisAmount_Currency,
rti.Amount_Amount [TaxAmount],
rti.Amount_Currency,
rti.ExternalJurisdictionLevelId [ExternalJurisdictionId],
rti.ExternalTaxImpositionType [ImpositionType],
rth.ReceivableCodeId [ReceivableCodeId],
@CreatedById,
@CreatedTime
FROM #ReceivableTaxHeader rth
INNER JOIN ReceivableTaxImpositions rti ON rth.ReceivableTaxImpositionId = rti.Id
DROP TABLE #ReceivableAsset;
DROP TABLE #InvoiceIdList;
DROP TABLE #ReceivableTaxHeader;
DROP TABLE #CTE_BillToDetails;
DROP TABLE #CustomerDetails;
DROP TABLE #BillToDetails;
END

GO
