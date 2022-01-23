SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveContractOrigination]
(
 @val [dbo].[ContractOrigination] READONLY
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
MERGE [dbo].[ContractOriginations] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AcquiredPortfolioId]=S.[AcquiredPortfolioId],[CommissionType]=S.[CommissionType],[CommissionValueExcludingVAT_Amount]=S.[CommissionValueExcludingVAT_Amount],[CommissionValueExcludingVAT_Currency]=S.[CommissionValueExcludingVAT_Currency],[DocFeeAmount_Amount]=S.[DocFeeAmount_Amount],[DocFeeAmount_Currency]=S.[DocFeeAmount_Currency],[DocFeeReceivableCodeId]=S.[DocFeeReceivableCodeId],[IsOriginationGeneratePayable]=S.[IsOriginationGeneratePayable],[ManagementSegment]=S.[ManagementSegment],[OriginatingLineofBusinessId]=S.[OriginatingLineofBusinessId],[OriginationChannelId]=S.[OriginationChannelId],[OriginationFee_Amount]=S.[OriginationFee_Amount],[OriginationFee_Currency]=S.[OriginationFee_Currency],[OriginationFeeBlendedItemCodeId]=S.[OriginationFeeBlendedItemCodeId],[OriginationScrapeFactor]=S.[OriginationScrapeFactor],[OriginationSourceId]=S.[OriginationSourceId],[OriginationSourceTypeId]=S.[OriginationSourceTypeId],[OriginationSourceUserId]=S.[OriginationSourceUserId],[OriginatorPayableRemitToId]=S.[OriginatorPayableRemitToId],[ProgramId]=S.[ProgramId],[ProgramVendorOriginationSourceId]=S.[ProgramVendorOriginationSourceId],[ScrapePayableCodeId]=S.[ScrapePayableCodeId],[ScrapeWithholdingTaxRate]=S.[ScrapeWithholdingTaxRate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AcquiredPortfolioId],[CommissionType],[CommissionValueExcludingVAT_Amount],[CommissionValueExcludingVAT_Currency],[CreatedById],[CreatedTime],[DocFeeAmount_Amount],[DocFeeAmount_Currency],[DocFeeReceivableCodeId],[IsOriginationGeneratePayable],[ManagementSegment],[OriginatingLineofBusinessId],[OriginationChannelId],[OriginationFee_Amount],[OriginationFee_Currency],[OriginationFeeBlendedItemCodeId],[OriginationScrapeFactor],[OriginationSourceId],[OriginationSourceTypeId],[OriginationSourceUserId],[OriginatorPayableRemitToId],[ProgramId],[ProgramVendorOriginationSourceId],[ScrapePayableCodeId],[ScrapeWithholdingTaxRate])
    VALUES (S.[AcquiredPortfolioId],S.[CommissionType],S.[CommissionValueExcludingVAT_Amount],S.[CommissionValueExcludingVAT_Currency],S.[CreatedById],S.[CreatedTime],S.[DocFeeAmount_Amount],S.[DocFeeAmount_Currency],S.[DocFeeReceivableCodeId],S.[IsOriginationGeneratePayable],S.[ManagementSegment],S.[OriginatingLineofBusinessId],S.[OriginationChannelId],S.[OriginationFee_Amount],S.[OriginationFee_Currency],S.[OriginationFeeBlendedItemCodeId],S.[OriginationScrapeFactor],S.[OriginationSourceId],S.[OriginationSourceTypeId],S.[OriginationSourceUserId],S.[OriginatorPayableRemitToId],S.[ProgramId],S.[ProgramVendorOriginationSourceId],S.[ScrapePayableCodeId],S.[ScrapeWithholdingTaxRate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
