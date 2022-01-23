SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePayOffTemplateTerminationTypeParameter]
(
 @val [dbo].[PayOffTemplateTerminationTypeParameter] READONLY
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
MERGE [dbo].[PayOffTemplateTerminationTypeParameters] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ApplicableForFixedTerm]=S.[ApplicableForFixedTerm],[DiscountRate]=S.[DiscountRate],[Factor]=S.[Factor],[FeeExclusionExpression]=S.[FeeExclusionExpression],[IsActive]=S.[IsActive],[IsExcludeFeeApplicable]=S.[IsExcludeFeeApplicable],[NumberofTerms]=S.[NumberofTerms],[PayableCodeId]=S.[PayableCodeId],[PayableWithholdingTaxRate]=S.[PayableWithholdingTaxRate],[ReceivableCodeId]=S.[ReceivableCodeId],[SundryType]=S.[SundryType],[TerminationTypeParameterConfigId]=S.[TerminationTypeParameterConfigId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ApplicableForFixedTerm],[CreatedById],[CreatedTime],[DiscountRate],[Factor],[FeeExclusionExpression],[IsActive],[IsExcludeFeeApplicable],[NumberofTerms],[PayableCodeId],[PayableWithholdingTaxRate],[PayOffTemplateTerminationTypeId],[ReceivableCodeId],[SundryType],[TerminationTypeParameterConfigId])
    VALUES (S.[ApplicableForFixedTerm],S.[CreatedById],S.[CreatedTime],S.[DiscountRate],S.[Factor],S.[FeeExclusionExpression],S.[IsActive],S.[IsExcludeFeeApplicable],S.[NumberofTerms],S.[PayableCodeId],S.[PayableWithholdingTaxRate],S.[PayOffTemplateTerminationTypeId],S.[ReceivableCodeId],S.[SundryType],S.[TerminationTypeParameterConfigId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
