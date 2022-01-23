SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveOneSourceExportDetailExtract]
(
 @val [dbo].[OneSourceExportDetailExtract] READONLY
)
AS
SET NOCOUNT ON;
DECLARE @Output TABLE(
 [Action] NVARCHAR(10) NOT NULL,
 [Id] bigint NOT NULL,
 [Token] int NOT NULL,
 [RowVersion] BIGINT,
 [OldRowVersion] BIGINT
)
MERGE [dbo].[OneSourceExportDetailExtracts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AcquisitionDate]=S.[AcquisitionDate],[AgreementCustomerName]=S.[AgreementCustomerName],[AsOfDate]=S.[AsOfDate],[AssetAddressLine1]=S.[AssetAddressLine1],[AssetAddressLine2]=S.[AssetAddressLine2],[AssetAddressLine3]=S.[AssetAddressLine3],[AssetCity]=S.[AssetCity],[AssetCost]=S.[AssetCost],[AssetCountyName]=S.[AssetCountyName],[AssetDescription]=S.[AssetDescription],[AssetNumber]=S.[AssetNumber],[AssetSerialNumber]=S.[AssetSerialNumber],[AssetState]=S.[AssetState],[AssetZipCode]=S.[AssetZipCode],[CustomerAddressLine1]=S.[CustomerAddressLine1],[CustomerAddressLine2]=S.[CustomerAddressLine2],[CustomerAddressLine3]=S.[CustomerAddressLine3],[CustomerCity]=S.[CustomerCity],[CustomerState]=S.[CustomerState],[CustomerZipCode]=S.[CustomerZipCode],[EquipmentCode]=S.[EquipmentCode],[FederalTaxDep]=S.[FederalTaxDep],[FileName]=S.[FileName],[IsDisposedAssetReported]=S.[IsDisposedAssetReported],[IsIncluded]=S.[IsIncluded],[ItemType]=S.[ItemType],[JobStepInstanceId]=S.[JobStepInstanceId],[LeaseNumber]=S.[LeaseNumber],[LeaseType]=S.[LeaseType],[LegalEntityId]=S.[LegalEntityId],[Manufacturer]=S.[Manufacturer],[ModelYear]=S.[ModelYear],[PreviousLeaseNumber]=S.[PreviousLeaseNumber],[Quantity]=S.[Quantity],[RejectReason]=S.[RejectReason],[SalesTaxRate]=S.[SalesTaxRate],[TaxExempt]=S.[TaxExempt],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AcquisitionDate],[AgreementCustomerName],[AsOfDate],[AssetAddressLine1],[AssetAddressLine2],[AssetAddressLine3],[AssetCity],[AssetCost],[AssetCountyName],[AssetDescription],[AssetNumber],[AssetSerialNumber],[AssetState],[AssetZipCode],[CreatedById],[CreatedTime],[CustomerAddressLine1],[CustomerAddressLine2],[CustomerAddressLine3],[CustomerCity],[CustomerState],[CustomerZipCode],[EquipmentCode],[FederalTaxDep],[FileName],[IsDisposedAssetReported],[IsIncluded],[ItemType],[JobStepInstanceId],[LeaseNumber],[LeaseType],[LegalEntityId],[Manufacturer],[ModelYear],[PreviousLeaseNumber],[Quantity],[RejectReason],[SalesTaxRate],[TaxExempt])
    VALUES (S.[AcquisitionDate],S.[AgreementCustomerName],S.[AsOfDate],S.[AssetAddressLine1],S.[AssetAddressLine2],S.[AssetAddressLine3],S.[AssetCity],S.[AssetCost],S.[AssetCountyName],S.[AssetDescription],S.[AssetNumber],S.[AssetSerialNumber],S.[AssetState],S.[AssetZipCode],S.[CreatedById],S.[CreatedTime],S.[CustomerAddressLine1],S.[CustomerAddressLine2],S.[CustomerAddressLine3],S.[CustomerCity],S.[CustomerState],S.[CustomerZipCode],S.[EquipmentCode],S.[FederalTaxDep],S.[FileName],S.[IsDisposedAssetReported],S.[IsIncluded],S.[ItemType],S.[JobStepInstanceId],S.[LeaseNumber],S.[LeaseType],S.[LegalEntityId],S.[Manufacturer],S.[ModelYear],S.[PreviousLeaseNumber],S.[Quantity],S.[RejectReason],S.[SalesTaxRate],S.[TaxExempt])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
