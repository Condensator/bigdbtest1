SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE [dbo].[AssetSaleStatementInvoiceSummary]
(
@AssetSaleId Bigint
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT
LegalEntityLogoImageContent = CASE WHEN L.LogoImageFile_Content IS NOT NULL AND L.LogoImageFile_Content <> 0x
THEN (SELECT FS.Content FROM FileStores FS WHERE FS.Guid = dbo.GetContentGuid(L.LogoImageFile_Content))
ELSE NULL END
,L.LogoImageFile_Source
,LegalEntityLogoImageType = 'image/'+ L.LogoImageFile_Type
,ASI.TransactionNumber [QuoteNumber]
,RT.Name [RemitToName]
,LEA.AddressLine1 [RemittoAddressline1]
,LEA.AddressLine2 [RemittoAddressline2]
,LEA.City [RemittoCity]
,LEA.PostalCode [RemittoPostalCode]
,LEC.FullName [RemittoContactName]
,BT.CustomerBillToName [BillToName]
,BPA.AddressLine1 [BilltoAddress1]
,BPA.AddressLine2 [BilltoAddress2]
,BPA.City [BilltoCity]
,BPA.PostalCode [BilltoPostalCode]
,BPC.FullName [BilltoContactName]
FROM
AssetSales ASI
JOIN RemitToes RT ON ASI.RemitToId = RT.Id
LEFT JOIN Logoes L ON RT.LogoId = L.Id
LEFT JOIN LegalEntityAddresses LEA ON RT.LegalEntityAddressId = LEA.Id
LEFT JOIN LegalEntityContacts LEC ON RT.LegalEntityContactId = LEC.Id
LEFT JOIN BillToes BT ON ASI.BillToId = BT.Id
LEFT JOIN PartyAddresses BPA ON BT.BillingAddressId = BPA.Id
LEFT JOIN PartyContacts BPC ON BT.BillingContactPersonId = BPC.Id
WHERE ASI.Id = @AssetSaleId
END

GO
