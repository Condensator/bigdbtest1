SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLoanSyndicationFundingSource]
(
 @val [dbo].[LoanSyndicationFundingSource] READONLY
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
MERGE [dbo].[LoanSyndicationFundingSources] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CashHoldbackAmount_Amount]=S.[CashHoldbackAmount_Amount],[CashHoldbackAmount_Currency]=S.[CashHoldbackAmount_Currency],[FunderBillToId]=S.[FunderBillToId],[FunderId]=S.[FunderId],[FunderLocationId]=S.[FunderLocationId],[FunderRemitToId]=S.[FunderRemitToId],[IsActive]=S.[IsActive],[LessorGuaranteedResidualAmount_Amount]=S.[LessorGuaranteedResidualAmount_Amount],[LessorGuaranteedResidualAmount_Currency]=S.[LessorGuaranteedResidualAmount_Currency],[ParticipationPercentage]=S.[ParticipationPercentage],[SalesTaxResponsibility]=S.[SalesTaxResponsibility],[ScrapeFactor]=S.[ScrapeFactor],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UpfrontSyndicationFee_Amount]=S.[UpfrontSyndicationFee_Amount],[UpfrontSyndicationFee_Currency]=S.[UpfrontSyndicationFee_Currency]
WHEN NOT MATCHED THEN
	INSERT ([CashHoldbackAmount_Amount],[CashHoldbackAmount_Currency],[CreatedById],[CreatedTime],[FunderBillToId],[FunderId],[FunderLocationId],[FunderRemitToId],[IsActive],[LessorGuaranteedResidualAmount_Amount],[LessorGuaranteedResidualAmount_Currency],[LoanSyndicationId],[ParticipationPercentage],[SalesTaxResponsibility],[ScrapeFactor],[UpfrontSyndicationFee_Amount],[UpfrontSyndicationFee_Currency])
    VALUES (S.[CashHoldbackAmount_Amount],S.[CashHoldbackAmount_Currency],S.[CreatedById],S.[CreatedTime],S.[FunderBillToId],S.[FunderId],S.[FunderLocationId],S.[FunderRemitToId],S.[IsActive],S.[LessorGuaranteedResidualAmount_Amount],S.[LessorGuaranteedResidualAmount_Currency],S.[LoanSyndicationId],S.[ParticipationPercentage],S.[SalesTaxResponsibility],S.[ScrapeFactor],S.[UpfrontSyndicationFee_Amount],S.[UpfrontSyndicationFee_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
