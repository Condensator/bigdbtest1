SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceivableCode]
(
 @val [dbo].[ReceivableCode] READONLY
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
MERGE [dbo].[ReceivableCodes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccountingTreatment]=S.[AccountingTreatment],[DefaultInvoiceComment]=S.[DefaultInvoiceComment],[DefaultInvoiceReceivableGroupingOption]=S.[DefaultInvoiceReceivableGroupingOption],[Description]=S.[Description],[GLTemplateId]=S.[GLTemplateId],[IncludeInEAR]=S.[IncludeInEAR],[IncludeInEARForCustomerType]=S.[IncludeInEARForCustomerType],[IncludeInPayoffOrPaydown]=S.[IncludeInPayoffOrPaydown],[IsActive]=S.[IsActive],[IsIncludeVATInEARForIndividual]=S.[IsIncludeVATInEARForIndividual],[IsRentalBased]=S.[IsRentalBased],[IsTaxExempt]=S.[IsTaxExempt],[IsVatInvoice]=S.[IsVatInvoice],[Name]=S.[Name],[PortfolioId]=S.[PortfolioId],[ReceivableCategoryId]=S.[ReceivableCategoryId],[ReceivableTypeId]=S.[ReceivableTypeId],[SyndicationGLTemplateId]=S.[SyndicationGLTemplateId],[TaxReceivableTypeId]=S.[TaxReceivableTypeId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WithholdingTaxCodeId]=S.[WithholdingTaxCodeId]
WHEN NOT MATCHED THEN
	INSERT ([AccountingTreatment],[CreatedById],[CreatedTime],[DefaultInvoiceComment],[DefaultInvoiceReceivableGroupingOption],[Description],[GLTemplateId],[IncludeInEAR],[IncludeInEARForCustomerType],[IncludeInPayoffOrPaydown],[IsActive],[IsIncludeVATInEARForIndividual],[IsRentalBased],[IsTaxExempt],[IsVatInvoice],[Name],[PortfolioId],[ReceivableCategoryId],[ReceivableTypeId],[SyndicationGLTemplateId],[TaxReceivableTypeId],[WithholdingTaxCodeId])
    VALUES (S.[AccountingTreatment],S.[CreatedById],S.[CreatedTime],S.[DefaultInvoiceComment],S.[DefaultInvoiceReceivableGroupingOption],S.[Description],S.[GLTemplateId],S.[IncludeInEAR],S.[IncludeInEARForCustomerType],S.[IncludeInPayoffOrPaydown],S.[IsActive],S.[IsIncludeVATInEARForIndividual],S.[IsRentalBased],S.[IsTaxExempt],S.[IsVatInvoice],S.[Name],S.[PortfolioId],S.[ReceivableCategoryId],S.[ReceivableTypeId],S.[SyndicationGLTemplateId],S.[TaxReceivableTypeId],S.[WithholdingTaxCodeId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
