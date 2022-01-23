SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceiptSyndicatedReceivables_Extract]
(
 @val [dbo].[ReceiptSyndicatedReceivables_Extract] READONLY
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
MERGE [dbo].[ReceiptSyndicatedReceivables_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [FunderBillToId]=S.[FunderBillToId],[FunderLocationId]=S.[FunderLocationId],[FunderRemitToId]=S.[FunderRemitToId],[InvoiceReceivableGroupingOption]=S.[InvoiceReceivableGroupingOption],[JobStepInstanceId]=S.[JobStepInstanceId],[ReceivableId]=S.[ReceivableId],[ReceivableRemitToId]=S.[ReceivableRemitToId],[RentalProceedsPayableCodeId]=S.[RentalProceedsPayableCodeId],[RentalProceedsPayableCodeName]=S.[RentalProceedsPayableCodeName],[ScrapeFactor]=S.[ScrapeFactor],[ScrapeReceivableCodeId]=S.[ScrapeReceivableCodeId],[TaxRemitFunderId]=S.[TaxRemitFunderId],[TaxRemitToId]=S.[TaxRemitToId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UtilizedScrapeAmount]=S.[UtilizedScrapeAmount],[WithholdingTaxRate]=S.[WithholdingTaxRate]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[FunderBillToId],[FunderLocationId],[FunderRemitToId],[InvoiceReceivableGroupingOption],[JobStepInstanceId],[ReceivableId],[ReceivableRemitToId],[RentalProceedsPayableCodeId],[RentalProceedsPayableCodeName],[ScrapeFactor],[ScrapeReceivableCodeId],[TaxRemitFunderId],[TaxRemitToId],[UtilizedScrapeAmount],[WithholdingTaxRate])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[FunderBillToId],S.[FunderLocationId],S.[FunderRemitToId],S.[InvoiceReceivableGroupingOption],S.[JobStepInstanceId],S.[ReceivableId],S.[ReceivableRemitToId],S.[RentalProceedsPayableCodeId],S.[RentalProceedsPayableCodeName],S.[ScrapeFactor],S.[ScrapeReceivableCodeId],S.[TaxRemitFunderId],S.[TaxRemitToId],S.[UtilizedScrapeAmount],S.[WithholdingTaxRate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
