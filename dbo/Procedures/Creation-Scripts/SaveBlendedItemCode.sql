SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveBlendedItemCode]
(
 @val [dbo].[BlendedItemCode] READONLY
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
MERGE [dbo].[BlendedItemCodes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccumulateExpense]=S.[AccumulateExpense],[BookingGLTemplateId]=S.[BookingGLTemplateId],[BookRecognitionMode]=S.[BookRecognitionMode],[Description]=S.[Description],[EntityType]=S.[EntityType],[Frequency]=S.[Frequency],[GeneratePayableOrReceivable]=S.[GeneratePayableOrReceivable],[IncludeInBlendedYield]=S.[IncludeInBlendedYield],[IncludeInClassificationTest]=S.[IncludeInClassificationTest],[IncludeInPayoffOrPaydown]=S.[IncludeInPayoffOrPaydown],[IsActive]=S.[IsActive],[IsAssetBased]=S.[IsAssetBased],[IsFAS91]=S.[IsFAS91],[IsVendorCommission]=S.[IsVendorCommission],[IsVendorSubsidy]=S.[IsVendorSubsidy],[Name]=S.[Name],[Occurrence]=S.[Occurrence],[PayableCodeId]=S.[PayableCodeId],[PayableWithholdingTaxRate]=S.[PayableWithholdingTaxRate],[PortfolioId]=S.[PortfolioId],[ReceivableCodeId]=S.[ReceivableCodeId],[RecognitionGLTemplateId]=S.[RecognitionGLTemplateId],[RecognitionMethod]=S.[RecognitionMethod],[TaxCredit]=S.[TaxCredit],[TaxDepTemplateId]=S.[TaxDepTemplateId],[TaxRecognitionMode]=S.[TaxRecognitionMode],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccumulateExpense],[BookingGLTemplateId],[BookRecognitionMode],[CreatedById],[CreatedTime],[Description],[EntityType],[Frequency],[GeneratePayableOrReceivable],[IncludeInBlendedYield],[IncludeInClassificationTest],[IncludeInPayoffOrPaydown],[IsActive],[IsAssetBased],[IsFAS91],[IsVendorCommission],[IsVendorSubsidy],[Name],[Occurrence],[PayableCodeId],[PayableWithholdingTaxRate],[PortfolioId],[ReceivableCodeId],[RecognitionGLTemplateId],[RecognitionMethod],[TaxCredit],[TaxDepTemplateId],[TaxRecognitionMode],[Type])
    VALUES (S.[AccumulateExpense],S.[BookingGLTemplateId],S.[BookRecognitionMode],S.[CreatedById],S.[CreatedTime],S.[Description],S.[EntityType],S.[Frequency],S.[GeneratePayableOrReceivable],S.[IncludeInBlendedYield],S.[IncludeInClassificationTest],S.[IncludeInPayoffOrPaydown],S.[IsActive],S.[IsAssetBased],S.[IsFAS91],S.[IsVendorCommission],S.[IsVendorSubsidy],S.[Name],S.[Occurrence],S.[PayableCodeId],S.[PayableWithholdingTaxRate],S.[PortfolioId],S.[ReceivableCodeId],S.[RecognitionGLTemplateId],S.[RecognitionMethod],S.[TaxCredit],S.[TaxDepTemplateId],S.[TaxRecognitionMode],S.[Type])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
