SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePayableInvoiceAsset]
(
 @val [dbo].[PayableInvoiceAsset] READONLY
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
MERGE [dbo].[PayableInvoiceAssets] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AcquisitionCost_Amount]=S.[AcquisitionCost_Amount],[AcquisitionCost_Currency]=S.[AcquisitionCost_Currency],[AcquisitionLocationId]=S.[AcquisitionLocationId],[AssetId]=S.[AssetId],[EquipmentVendorId]=S.[EquipmentVendorId],[InterestUpdateLastDate]=S.[InterestUpdateLastDate],[InterimInterestStartDate]=S.[InterimInterestStartDate],[IsActive]=S.[IsActive],[OtherCost_Amount]=S.[OtherCost_Amount],[OtherCost_Currency]=S.[OtherCost_Currency],[TaxCodeId]=S.[TaxCodeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VATAmount_Amount]=S.[VATAmount_Amount],[VATAmount_Currency]=S.[VATAmount_Currency],[VATType]=S.[VATType]
WHEN NOT MATCHED THEN
	INSERT ([AcquisitionCost_Amount],[AcquisitionCost_Currency],[AcquisitionLocationId],[AssetId],[CreatedById],[CreatedTime],[EquipmentVendorId],[InterestUpdateLastDate],[InterimInterestStartDate],[IsActive],[OtherCost_Amount],[OtherCost_Currency],[PayableInvoiceId],[TaxCodeId],[VATAmount_Amount],[VATAmount_Currency],[VATType])
    VALUES (S.[AcquisitionCost_Amount],S.[AcquisitionCost_Currency],S.[AcquisitionLocationId],S.[AssetId],S.[CreatedById],S.[CreatedTime],S.[EquipmentVendorId],S.[InterestUpdateLastDate],S.[InterimInterestStartDate],S.[IsActive],S.[OtherCost_Amount],S.[OtherCost_Currency],S.[PayableInvoiceId],S.[TaxCodeId],S.[VATAmount_Amount],S.[VATAmount_Currency],S.[VATType])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
