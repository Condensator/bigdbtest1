SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AssetSaleInvoiceReport]
(
@InvoiceNumber NvarChar(40)
--@AddendumPagesCount INT Null
)
AS
BEGIN
SET NOCOUNT ON;
DECLARE @InvoiceId BIGINT
--DECLARE @InvoiceNumber NvarChar(40)
--SET @InvoiceNumber=1181
SELECT @InvoiceId=Id FROm ReceivableInvoices WHERE Number=@InvoiceNumber
SET NOCOUNT ON;
WITH CTE_ReceivableInvoiceData AS
(
SELECT
ReceivableInvoiceId=Temp_ReceivableInvoiceDetails.ReceivableInvoiceId,
ContractId=ReceivableInvoiceDetails.EntityId,
SequenceNumber=Contracts.SequenceNumber
FROM
(
SELECT
ReceivableInvoiceId
FROM ReceivableInvoiceDetails
WHERE
EntityType ='CT' AND ReceivableInvoiceId = @InvoiceId
GROUP by ReceivableInvoiceId
Having Count(EntityId) = 1
)As Temp_ReceivableInvoiceDetails
INNER JOIN ReceivableInvoiceDetails ON ReceivableInvoiceDetails.ReceivableInvoiceId=Temp_ReceivableInvoiceDetails.ReceivableInvoiceId
AND EntityType ='CT'
INNER JOIN Contracts ON ReceivableInvoiceDetails.EntityId=Contracts.Id
),
CTE_ContractDetails As
(
SELECT ContractId,PurchaseOrderNumber=PurchaseOrderNumber FROm LeaseFinances WHERE IsCurrent=1
UNION ALL
SELECT ContractId,PurchaseOrderNumber=ContractPurchaseOrderNumber  FROm LoanFinances WHERE IsCurrent=1
)
SELECT
ReceivableInvoices.Number[InvoiceNumber],
--InvoiceFormats.InvoiceTypeId,
--InvoiceTypeLabelConfigs.Id
ReceivableInvoices.InvoiceRunDate[InvoiceRunDate],
ReceivableInvoices.DueDate[DueDate],
CTE_ReceivableInvoiceData.SequenceNumber,
CTE_ContractDetails.PurchaseOrderNumber[PO_],
SUBSTRING(cus.InvoiceComment ,1, 200) [CustomerComments],
cus.InvoiceCommentBeginDate [CustomerInvoiceCommentBeginDate],
cus.InvoiceCommentEndDate [CustomerInvoiceCommentEndDate],
BillToes.CustomerBillToName[CustomerName],
BillToes.InvoiceNumberLabel [InvoiceNumberLabel],
BillToes.InvoiceDateLabel [InvoiceRunDateLabel],
pc2.FullName[AttentionLine],
ReceivableInvoices.InvoiceAmount_Amount[ReceivableAmount],
ReceivableInvoices.InvoiceAmount_Currency[Currency],
ReceivableInvoices.InvoiceTaxAmount_Amount[TaxAmount],
ISNULL(ReceivableInvoices.InvoiceAmount_Amount,0) + ISNULL(ReceivableInvoices.InvoiceTaxAmount_Amount,0) 'TotalAmountDue',
RemitToes.Name[RemitToName],
ReceivableInvoices.IsACH[IsACH],
RemitToes.Code[RemitToCode],
pa.AddressLine1 [BillingAddressLine1],
pa.AddressLine2 [BillingAddressLine2],
pa.City [BillingCity],
pa.PostalCode [BillingZip],
billingState.ShortName[BillingState],
billingCountry.ShortName[BillingCountry],
ISNULL(lea.AddressLine1,pa2.AddressLine1) [LessorAddressLine1],
ISNULL(lea.AddressLine2,pa2.AddressLine2) [LessorAddressLine2],
ISNULL(lea.City,pa2.City) [LessorCity],
ISNULL(legalEntityState.ShortName,partyState.ShortName)[LessorState],
ISNULL(lea.PostalCode,pa2.PostalCode) [LessorZip],
--ISNULL(legalEntityCountry.ShortName,partyCountry.ShortName) [LessorCountry],
REPLACE(REPLACE(ISNULL(lec.PhoneNumber1,pc.PhoneNumber1),'-',''),' ','') [LessorContactPhone],
ISNULL(lec.EMailId,pc.EMailId) [LessorContactEmail],
LegalEntities.LessorWebAddress [LessorWebAddress],
RIGHT('00000000000'+ CONVERT(VARCHAR,dbo.GetOCRCodes(LegalEntities.LegalEntityNumber)),12) +' '+ RIGHT('000000000'+ CONVERT(VARCHAR,Parties.PartyNumber),10) +' '+
RIGHT('000000000000000000000000000'+ CONVERT(VARCHAR,dbo.GetOCRCodes(CTE_ReceivableInvoiceData.SequenceNumber)),28)  +' '+  RIGHT('000000000'+ CONVERT(VARCHAR,ReceivableInvoices.Number),10)+' ' +
RIGHT('000000000'+ CONVERT(VARCHAR,(REPLACE((ReceivableInvoices.InvoiceAmount_Amount + ReceivableInvoices.InvoiceTaxAmount_Amount ),'.',''))),10) +' '+
RIGHT('0000000'+ CONVERT(VARCHAR,(REPLACE(CONVERT(VARCHAR(10),ReceivableInvoices.DueDate,101),'/',''))),8) [OCRMCR],
CASE WHEN logo.LogoImageFile_Content IS NOT NULL AND logo.LogoImageFile_Content <> 0x THEN
(SELECT fs.Content FROM FileStores fs WHERE fs.Guid = dbo.GetContentGuid(logo.LogoImageFile_Content))
ELSE NULL END 'LogoImageFile_Content',
logo.LogoImageFile_Type,
InvoiceTypeLabelConfigs.Name[InvoiceType]
FROM ReceivableInvoices
INNER JOIN LegalEntities ON ReceivableInvoices.LegalEntityId = LegalEntities.Id AND ReceivableInvoices.Id=@InvoiceId
INNER JOIN RemitToes ON ReceivableInvoices.RemitToId = RemitToes.Id
INNER JOIN BillToes ON ReceivableInvoices.BillToId = BillToes.Id
--INNER JOIN BillToInvoiceFormats ON BillToes.Id = BillToInvoiceFormats.BillToId
INNER JOIN InvoiceFormats ON ReceivableInvoices.ReportFormatId = InvoiceFormats.Id  --AND InvoiceFormats.Name='Non Rental'
INNER JOIN InvoiceTypeLabelConfigs ON InvoiceFormats.InvoiceTypeId = InvoiceTypeLabelConfigs.InvoiceTypeId
INNER JOIN Customers cus ON ReceivableInvoices.CustomerId = cus.Id
INNER JOIN Parties ON ReceivableInvoices.CustomerId = Parties.Id
INNER JOIN PartyAddresses pa ON BillToes.BillingAddressId = pa.Id
INNER JOIN States billingState ON pa.StateId = billingState.Id
INNER JOIN Countries billingCountry ON billingState.CountryId = billingCountry.Id
LEFT JOIN CTE_ReceivableInvoiceData ON CTE_ReceivableInvoiceData.ReceivableInvoiceId=ReceivableInvoices.Id
LEFT JOIN CTE_ContractDetails ON CTE_ContractDetails.ContractId=CTE_ReceivableInvoiceData.ContractId
LEFT JOIN  Logoes logo ON logo.Id = RemitToes.LogoId
----INNER JOIN PartyContacts ON BillToes.BillingContactPersonId = PartyContacts.Id
LEFT JOIN dbo.PartyContacts pc2 ON BillToes.BillingContactPersonId = pc2.Id
LEFT JOIN dbo.LegalEntityAddresses lea ON RemitToes.LegalEntityAddressId = lea.Id
LEFT JOIN dbo.States legalEntityState ON lea.StateId = legalEntityState.Id
LEFT JOIN Countries legalEntityCountry ON legalEntityState.CountryId = legalEntityCountry.Id
LEFT JOIN dbo.LegalEntityContacts lec ON RemitToes.LegalEntityContactId = lec.Id
LEFT JOIN dbo.PartyAddresses pa2 ON RemitToes.PartyAddressId = pa2.Id
LEFT JOIN dbo.States partyState ON pa2.StateId = partyState.Id
LEFT JOIN Countries partyCountry ON partyState.CountryId = partyCountry.Id
LEFT JOIN dbo.PartyContacts pc ON RemitToes.PartyContactId = pc.Id
END

GO
