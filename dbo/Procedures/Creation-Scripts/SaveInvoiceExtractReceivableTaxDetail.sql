SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveInvoiceExtractReceivableTaxDetail]
(
 @val [dbo].[InvoiceExtractReceivableTaxDetail] READONLY
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
MERGE [dbo].[InvoiceExtractReceivableTaxDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[ExternalJurisdictionId]=S.[ExternalJurisdictionId],[ImpositionType]=S.[ImpositionType],[InvoiceId]=S.[InvoiceId],[ReceivableCodeId]=S.[ReceivableCodeId],[ReceivableDetailId]=S.[ReceivableDetailId],[ReceivableTaxDetailId]=S.[ReceivableTaxDetailId],[Rent_Amount]=S.[Rent_Amount],[Rent_Currency]=S.[Rent_Currency],[TaxAmount_Amount]=S.[TaxAmount_Amount],[TaxAmount_Currency]=S.[TaxAmount_Currency],[TaxCodeId]=S.[TaxCodeId],[TaxRate]=S.[TaxRate],[TaxTreatment]=S.[TaxTreatment],[TaxTypeId]=S.[TaxTypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[CreatedById],[CreatedTime],[ExternalJurisdictionId],[ImpositionType],[InvoiceId],[ReceivableCodeId],[ReceivableDetailId],[ReceivableTaxDetailId],[Rent_Amount],[Rent_Currency],[TaxAmount_Amount],[TaxAmount_Currency],[TaxCodeId],[TaxRate],[TaxTreatment],[TaxTypeId])
    VALUES (S.[AssetId],S.[CreatedById],S.[CreatedTime],S.[ExternalJurisdictionId],S.[ImpositionType],S.[InvoiceId],S.[ReceivableCodeId],S.[ReceivableDetailId],S.[ReceivableTaxDetailId],S.[Rent_Amount],S.[Rent_Currency],S.[TaxAmount_Amount],S.[TaxAmount_Currency],S.[TaxCodeId],S.[TaxRate],S.[TaxTreatment],S.[TaxTypeId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
