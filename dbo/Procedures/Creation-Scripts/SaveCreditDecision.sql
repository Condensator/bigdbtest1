SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCreditDecision]
(
 @val [dbo].[CreditDecision] READONLY
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
MERGE [dbo].[CreditDecisions] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ApprovedAmount_Amount]=S.[ApprovedAmount_Amount],[ApprovedAmount_Currency]=S.[ApprovedAmount_Currency],[ApprovedById]=S.[ApprovedById],[ApprovedOnBehalfUserId]=S.[ApprovedOnBehalfUserId],[ApprovedTransactionAmount_Amount]=S.[ApprovedTransactionAmount_Amount],[ApprovedTransactionAmount_Currency]=S.[ApprovedTransactionAmount_Currency],[BusinessAdditionalCollateral]=S.[BusinessAdditionalCollateral],[DecisionComments]=S.[DecisionComments],[DecisionDate]=S.[DecisionDate],[DecisionDocumentation]=S.[DecisionDocumentation],[DecisionName]=S.[DecisionName],[DecisionStatus]=S.[DecisionStatus],[ExpiryDate]=S.[ExpiryDate],[Intention]=S.[Intention],[IsActive]=S.[IsActive],[IsApprovedOnBehalf]=S.[IsApprovedOnBehalf],[IsAvailableBalanceCalculated]=S.[IsAvailableBalanceCalculated],[IsCarveOutUsed]=S.[IsCarveOutUsed],[IsConditionalApproval]=S.[IsConditionalApproval],[IsRevolving]=S.[IsRevolving],[IsSingleLoanAuthorityUsed]=S.[IsSingleLoanAuthorityUsed],[LGDCodeId]=S.[LGDCodeId],[LowSideOverride]=S.[LowSideOverride],[LowSideOverrideReasonCodeId]=S.[LowSideOverrideReasonCodeId],[OtherCreditApprovalCondition]=S.[OtherCreditApprovalCondition],[PrincipalAdditionalCollateral]=S.[PrincipalAdditionalCollateral],[RACOverride]=S.[RACOverride],[RACOverrideReason]=S.[RACOverrideReason],[ReplacementAmount_Amount]=S.[ReplacementAmount_Amount],[ReplacementAmount_Currency]=S.[ReplacementAmount_Currency],[SameDayCreditApprovals_Amount]=S.[SameDayCreditApprovals_Amount],[SameDayCreditApprovals_Currency]=S.[SameDayCreditApprovals_Currency],[SecurityDepositAmount_Amount]=S.[SecurityDepositAmount_Amount],[SecurityDepositAmount_Currency]=S.[SecurityDepositAmount_Currency],[StandardCollateral]=S.[StandardCollateral],[StatusChangedById]=S.[StatusChangedById],[StatusDate]=S.[StatusDate],[ToleranceAmount_Amount]=S.[ToleranceAmount_Amount],[ToleranceAmount_Currency]=S.[ToleranceAmount_Currency],[ToleranceFactor]=S.[ToleranceFactor],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UsedAmount_Amount]=S.[UsedAmount_Amount],[UsedAmount_Currency]=S.[UsedAmount_Currency],[WriteUp]=S.[WriteUp]
WHEN NOT MATCHED THEN
	INSERT ([ApprovedAmount_Amount],[ApprovedAmount_Currency],[ApprovedById],[ApprovedOnBehalfUserId],[ApprovedTransactionAmount_Amount],[ApprovedTransactionAmount_Currency],[BusinessAdditionalCollateral],[CreatedById],[CreatedTime],[CreditProfileId],[DecisionComments],[DecisionDate],[DecisionDocumentation],[DecisionName],[DecisionStatus],[ExpiryDate],[Intention],[IsActive],[IsApprovedOnBehalf],[IsAvailableBalanceCalculated],[IsCarveOutUsed],[IsConditionalApproval],[IsRevolving],[IsSingleLoanAuthorityUsed],[LGDCodeId],[LowSideOverride],[LowSideOverrideReasonCodeId],[OtherCreditApprovalCondition],[PrincipalAdditionalCollateral],[RACOverride],[RACOverrideReason],[ReplacementAmount_Amount],[ReplacementAmount_Currency],[SameDayCreditApprovals_Amount],[SameDayCreditApprovals_Currency],[SecurityDepositAmount_Amount],[SecurityDepositAmount_Currency],[StandardCollateral],[StatusChangedById],[StatusDate],[ToleranceAmount_Amount],[ToleranceAmount_Currency],[ToleranceFactor],[UsedAmount_Amount],[UsedAmount_Currency],[WriteUp])
    VALUES (S.[ApprovedAmount_Amount],S.[ApprovedAmount_Currency],S.[ApprovedById],S.[ApprovedOnBehalfUserId],S.[ApprovedTransactionAmount_Amount],S.[ApprovedTransactionAmount_Currency],S.[BusinessAdditionalCollateral],S.[CreatedById],S.[CreatedTime],S.[CreditProfileId],S.[DecisionComments],S.[DecisionDate],S.[DecisionDocumentation],S.[DecisionName],S.[DecisionStatus],S.[ExpiryDate],S.[Intention],S.[IsActive],S.[IsApprovedOnBehalf],S.[IsAvailableBalanceCalculated],S.[IsCarveOutUsed],S.[IsConditionalApproval],S.[IsRevolving],S.[IsSingleLoanAuthorityUsed],S.[LGDCodeId],S.[LowSideOverride],S.[LowSideOverrideReasonCodeId],S.[OtherCreditApprovalCondition],S.[PrincipalAdditionalCollateral],S.[RACOverride],S.[RACOverrideReason],S.[ReplacementAmount_Amount],S.[ReplacementAmount_Currency],S.[SameDayCreditApprovals_Amount],S.[SameDayCreditApprovals_Currency],S.[SecurityDepositAmount_Amount],S.[SecurityDepositAmount_Currency],S.[StandardCollateral],S.[StatusChangedById],S.[StatusDate],S.[ToleranceAmount_Amount],S.[ToleranceAmount_Currency],S.[ToleranceFactor],S.[UsedAmount_Amount],S.[UsedAmount_Currency],S.[WriteUp])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
