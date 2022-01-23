SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetPayoffInvoiceDetails]
(
@PayoffId BIGINT,
@PayoffReceivableSourceTableValue NVARCHAR(20),
@InvoiceNumber NVARCHAR(50),
@IsSyndicated BIT,
@ReceivableInvoiceId BIGINT,
@BillToId BIGINT,
@IsPrimaryInvoice BIT
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
DECLARE @ConvertedDueDate VARCHAR(20) = (SELECT REPLACE(CONVERT(VARCHAR(10),pf.DueDate, 101), '/', '') [MMYYYY] FROM dbo.Payoffs pf WHERE pf.Id = @PayoffId);
DECLARE @PayoffType NVARCHAR(6) ='Payoff';
DECLARE @BuyoutType NVARCHAR(6) ='Buyout';
DECLARE @SundryType NVARCHAR(6) ='Sundry';
DECLARE @EstimatedPropertyTaxType NVARCHAR(15) = 'EstimatedPropertyTax';
DECLARE @SecurityDepositType NVARCHAR(15)='SecurityDeposit';
CREATE TABLE #PayoffReceivablesInfo
(
ReceivableId BIGINT,
Amount DECIMAL(16,2),
Type NVARCHAR(20)
)
CREATE CLUSTERED INDEX IDX_PAYOFFRECEIVABLEINFO ON #PayoffReceivablesInfo(ReceivableId)
CREATE TABLE #PayoffAmountInfo
(
Type NVARCHAR(50),
IsTax BIT,
Amount DECIMAL(16,2)
)
INSERT INTO #PayoffReceivablesInfo
SELECT
R.Id,
SUM(RD.Amount_Amount),
CASE WHEN R.ReceivableCodeId = PF.PayoffReceivableCodeId THEN @PayoffType
WHEN R.ReceivableCodeId = PF.BuyoutReceivableCodeId THEN @BuyoutType
WHEN R.ReceivableCodeId = PF.PropertyTaxEscrowReceivableCodeId THEN @EstimatedPropertyTaxType
ELSE @SundryType
END
FROM Receivables R
JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
JOIN ReceivableInvoiceDetails RID ON RD.Id = RID.ReceivableDetailId
JOIN Payoffs PF ON R.SourceId = PF.Id AND R.SourceTable = @PayoffReceivableSourceTableValue
WHERE RID.ReceivableInvoiceId = @ReceivableInvoiceId
AND RID.IsActive = 1
AND R.IsActive = 1
AND RD.IsActive = 1
AND PF.Id = @PayoffId
GROUP BY R.Id, R.ReceivableCodeId,PF.PayoffReceivableCodeId,PF.BuyoutReceivableCodeId,PF.PropertyTaxEscrowReceivableCodeId
INSERT INTO #PayoffAmountInfo
SELECT Type = PR.Type, IsTax = 1, Amount = SUM(RTX.Amount_Amount)
FROM ReceivableTaxes RTX
JOIN #PayoffReceivablesInfo PR ON RTX.ReceivableId = PR.ReceivableId AND RTX.ReceivableId = PR.ReceivableId
WHERE RTX.IsActive = 1
GROUP BY PR.Type
INSERT INTO #PayoffAmountInfo
SELECT Type = PR.Type, IsTax = 0, Amount = SUM(PR.Amount)
FROM #PayoffReceivablesInfo PR
GROUP BY PR.Type
IF @IsPrimaryInvoice = 1
BEGIN
INSERT INTO #PayoffAmountInfo
SELECT Type=@SecurityDepositType, IsTax = 0, Amount = SUM(PSD.AppliedToPayoff_Amount)
FROM PayoffSecurityDeposits PSD
WHERE PSD.PayoffId = @PayoffId
AND PSD.IsActive = 1
END
SELECT
PayoffId = @PayoffId,
OriginationSourceName = (CASE
WHEN (OS.Name = 'Vendor' OR OS.Name = 'Indirect') AND @IsSyndicated=1 AND RTS.IsPrivateLabel = 1 AND CS.IsPrivateLabel = 1 THEN OS.Name
WHEN (OS.Name = 'Vendor' OR OS.Name = 'Indirect') AND @IsSyndicated =1 AND  CS.IsPrivateLabel = 0 AND RTS.IsPrivateLabel = 0 THEN 'Indirect'
WHEN (OS.Name = 'Direct') AND @IsSyndicated=1 AND RTS.IsPrivateLabel = 0 THEN 'Indirect'
WHEN (OS.Name = 'Vendor' OR OS.Name = 'Indirect') AND @IsSyndicated = 0 AND CS.IsPrivateLabel = 1 THEN OS.Name
ELSE 'Direct' END),
OriginationSourceId = (CASE
WHEN (OS.Name = 'Vendor' OR OS.Name = 'Indirect') AND @IsSyndicated = 0 AND CS.IsPrivateLabel = 1 THEN CO.OriginationSourceId
WHEN (OS.Name = 'Vendor' OR OS.Name = 'Indirect') AND @IsSyndicated = 1 AND CS.IsPrivateLabel = 1 AND RTS.IsPrivateLabel = 1 THEN CO.OriginationSourceId
WHEN (OS.Name = 'Vendor' OR OS.Name = 'Indirect') AND @IsSyndicated = 1 AND CS.IsPrivateLabel = 0 AND RTS.IsPrivateLabel = 0 THEN RTF.FunderId
WHEN (OS.Name = 'Direct') AND @IsSyndicated= 1 AND RTS.IsPrivateLabel = 0 THEN RTF.FunderId
ELSE LF.LegalEntityId END)
INTO #ContractOriginationDetails
FROM LeaseFinances LF
JOIN Payoffs P ON LF.Id = P.LeaseFinanceId
LEFT JOIN ContractOriginations CO ON LF.ContractOriginationId = CO.Id
LEFT JOIN OriginationSourceTypes OS ON CO.OriginationSourceTypeId = OS.Id AND OS.IsActive=1
LEFT JOIN ContractOriginationServicingDetails CSD ON CO.Id  = CSD.ContractOriginationId
LEFT JOIN ServicingDetails CS ON CSD.ServicingDetailId = CS.Id AND CS.IsActive=1
LEFT JOIN ReceivableForTransfers RT ON RT.ContractId = LF.ContractId
LEFT JOIN ReceivableForTransferFundingSources RTF ON RT.Id  = RTF.ReceivableForTransferId AND RTF.IsActive =1
LEFT JOIN ReceivableForTransferServicings RTS ON RT.Id  = RTS.ReceivableForTransferId AND RTS.IsActive=1
WHERE P.Id = @PayoffId
SELECT  COI.PayoffId,COI.OriginationSourceId,COI.OriginationSourceName, COUNT(*) AS COUNT
INTO #ContractOriginationInfo
FROM #ContractOriginationDetails COI
GROUP BY
COI.OriginationSourceId,
COI.OriginationSourceName,
COI.PayoffId
DECLARE @TotalReceivableAmount DECIMAL(16,2) = ISNULL((SELECT SUM(Amount) FROM #PayoffAmountInfo WHERE Type <> @SecurityDepositType),0);
DECLARE @SecurityDepositApplied DECIMAL(16,2) = ISNULL((SELECT SUM(Amount) FROM #PayoffAmountInfo WHERE Type = @SecurityDepositType),0);
SELECT TOP 1
LegalEntityLogoImageContent = (CASE WHEN L.LogoImageFile_Content IS NOT NULL AND L.LogoImageFile_Content <> 0x THEN
(SELECT Content FROM FileStores WHERE Guid = dbo.GetContentGuid(L.LogoImageFile_Content))
ELSE NULL END)
,LegalEntityLogoImageType = CASE WHEN COD.OriginationSourceName <> 'Direct' THEN 'image/'+ L.LogoImageFile_Type ELSE 'image/'+ L.LogoImageFile_Type END
,LegalEntityName = RT.Name
,LegalEntityAddressLine1 = ISNULL(LEA.AddressLine1, PAR.AddressLine1)
,LegalEntityAddressLine2 = ISNULL(LEA.AddressLine2, PAR.AddressLine2)
,LegalEntityAddressLine3 = ISNULL(LEA.City, PAR.City)
,LegalEntityAddressLine4 = ISNULL(RS.ShortName+' ',PS.ShortName+' ')+ISNULL(LEA.PostalCode,PAR.PostalCode)
,CustomerName = BT.CustomerBillToName
,CustomerAddressLine1 = PA.AddressLine1
,CustomerAddressLine2 = PA.AddressLine2
,CustomerAddressLine3 = PA.City
,CustomerAddressLine4 = ISNULL(BS.ShortName+' ','')+ISNULL(PA.PostalCode,'')
,InvoiceDate = RI.InvoiceRunDate
,ContractNumber = CT.SequenceNumber
,DueDate = PF.DueDate
,Currency = CC.ISO
,PayoffReceivableAmount = ISNULL((SELECT SUM(Amount) FROM #PayoffAmountInfo WHERE Type = @PayoffType AND IsTax=0),0.0)
,BuyoutReceivableAmount = ISNULL((SELECT SUM(Amount) FROM #PayoffAmountInfo WHERE Type = @BuyoutType AND IsTax=0),0.0)
,SundryReceivableAmount = ISNULL((SELECT SUM(Amount) FROM #PayoffAmountInfo WHERE Type = @SundryType AND IsTax=0),0.0)
,EstimatedPropertyTaxReceivableAmount = ISNULL((SELECT SUM(Amount) FROM #PayoffAmountInfo WHERE Type = @EstimatedPropertyTaxType AND IsTax=0),0.0)
,PayoffTaxAmount = ISNULL((SELECT SUM(Amount) FROM #PayoffAmountInfo WHERE Type = @PayoffType AND IsTax=1),0.0)
,BuyoutTaxAmount =ISNULL((SELECT SUM(Amount) FROM #PayoffAmountInfo WHERE Type = @BuyoutType AND IsTax=1),0.0)
,SundryTaxAmount =  ISNULL((SELECT SUM(Amount) FROM #PayoffAmountInfo WHERE Type = @SundryType AND IsTax=1),0.0)
,EstimatedPropertyTypeTaxAmount =  ISNULL((SELECT SUM(Amount) FROM #PayoffAmountInfo WHERE Type = @EstimatedPropertyTaxType AND IsTax=1),0.0)
,ContactPhone = Replace(Replace(isnull(PCT.PhoneNumber1,LEC.PhoneNumber1),'-',''),' ','')
,ContactEmail = ISNULL(PCT.EMailId,LEC.EMailId)
,WebAddress = LE.LessorWebAddress
,SecurityDepositApplicationAmount = @SecurityDepositApplied
,CustomerComments = SUBSTRING(cu.InvoiceComment ,1, 200)
,CustomerInvoiceCommentBeginDate = cu.InvoiceCommentBeginDate
,CustomerInvoiceCommentEndDate = cu.InvoiceCommentEndDate
,AttentionLine = BTC.FullName
,OriginationSource = COD.OriginationSourceName
,OriginationSourceId = COD.OriginationSourceId
FROM Payoffs PF
JOIN LeaseFinances LF ON PF.LeaseFinanceId = LF.Id
JOIN Contracts CT ON LF.ContractId =  CT.Id
JOIN BillToes BT ON @BillToId = BT.Id
JOIN Parties P ON BT.CustomerId = P.Id
JOIN Customers Cu ON P.Id = Cu.Id
JOIN Currencies C ON CT.CurrencyId = C.Id
JOIN CurrencyCodes CC ON C.CurrencyCodeId = CC.Id
JOIN RemitToes RT ON PF.RemitToId = RT.Id
JOIN PartyAddresses PA ON BT.BillingAddressId = PA.Id
JOIN ReceivableInvoices RI ON @ReceivableInvoiceId = RI.Id
LEFT JOIN States BS ON PA.StateId = BS.Id
LEFT JOIN Countries BC ON BS.CountryId = BC.Id
LEFT JOIN LegalEntities LE ON LF.LegalEntityId = LE.Id
LEFT JOIN LegalEntityAddresses LEA ON RT.LegalEntityAddressId = LEA.Id
LEFT JOIN PartyAddresses PAR ON RT.PartyAddressId = PAR.Id
LEFT JOIN States RS ON LEA.StateId = RS.Id
LEFT JOIN States PS ON PAR.StateId = PS.Id
LEFT JOIN Countries RC ON RS.CountryId = RC.Id
LEFT JOIN Countries PC ON PS.CountryId = PC.Id
LEFT JOIN PartyContacts BTC ON BT.BillingContactPersonId = BTC.Id
LEFT JOIN LegalEntityContacts LEC ON RT.LegalEntityContactId = LEC.Id
LEFT JOIN PartyContacts PCT ON RT.PartyContactId = PCT.Id
LEFT JOIN #ContractOriginationInfo COD ON  PF.Id = COD.PayoffId
LEFT JOIN Logoes L ON RT.LogoId = L.Id
WHERE PF.Id = @PayoffId
DROP TABLE #PayoffReceivablesInfo
DROP TABLE #PayoffAmountInfo
DROP TABLE #ContractOriginationDetails
DROP TABLE #ContractOriginationInfo
END

GO
