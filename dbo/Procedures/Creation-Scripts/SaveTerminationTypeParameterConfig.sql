SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveTerminationTypeParameterConfig]
(
 @val [dbo].[TerminationTypeParameterConfig] READONLY
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
MERGE [dbo].[TerminationTypeParameterConfigs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ApplicableForFixedTerm]=S.[ApplicableForFixedTerm],[ApplicableForOTP]=S.[ApplicableForOTP],[BlendedItemCodeApplicable]=S.[BlendedItemCodeApplicable],[DiscountRateApplicable]=S.[DiscountRateApplicable],[Entity]=S.[Entity],[FactorApplicable]=S.[FactorApplicable],[IsActive]=S.[IsActive],[IsApplicableForFeeParameter]=S.[IsApplicableForFeeParameter],[IsApplicableForPayoffAtMaturity]=S.[IsApplicableForPayoffAtMaturity],[IsLease]=S.[IsLease],[Label]=S.[Label],[NumberofTermsApplicable]=S.[NumberofTermsApplicable],[OperatorSign]=S.[OperatorSign],[Parameter]=S.[Parameter],[Property]=S.[Property],[SundryCodeApplicable]=S.[SundryCodeApplicable],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ApplicableForFixedTerm],[ApplicableForOTP],[BlendedItemCodeApplicable],[CreatedById],[CreatedTime],[DiscountRateApplicable],[Entity],[FactorApplicable],[IsActive],[IsApplicableForFeeParameter],[IsApplicableForPayoffAtMaturity],[IsLease],[Label],[NumberofTermsApplicable],[OperatorSign],[Parameter],[Property],[SundryCodeApplicable])
    VALUES (S.[ApplicableForFixedTerm],S.[ApplicableForOTP],S.[BlendedItemCodeApplicable],S.[CreatedById],S.[CreatedTime],S.[DiscountRateApplicable],S.[Entity],S.[FactorApplicable],S.[IsActive],S.[IsApplicableForFeeParameter],S.[IsApplicableForPayoffAtMaturity],S.[IsLease],S.[Label],S.[NumberofTermsApplicable],S.[OperatorSign],S.[Parameter],S.[Property],S.[SundryCodeApplicable])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
