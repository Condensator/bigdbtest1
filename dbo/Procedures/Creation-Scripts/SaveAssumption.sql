SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssumption]
(
 @val [dbo].[Assumption] READONLY
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
MERGE [dbo].[Assumptions] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssumptionDate]=S.[AssumptionDate],[AssumptionReason]=S.[AssumptionReason],[ContractId]=S.[ContractId],[ContractType]=S.[ContractType],[IsAccountingApproved]=S.[IsAccountingApproved],[IsAMReviewCompleted]=S.[IsAMReviewCompleted],[IsAMReviewRequired]=S.[IsAMReviewRequired],[IsBillInAlternateCurrency]=S.[IsBillInAlternateCurrency],[IsCloneAssetLocation]=S.[IsCloneAssetLocation],[IsFundingApproved]=S.[IsFundingApproved],[IsSalesLeaseBackReviewCompleted]=S.[IsSalesLeaseBackReviewCompleted],[IsSalesTaxExemption]=S.[IsSalesTaxExemption],[IsSalesTaxReviewCompleted]=S.[IsSalesTaxReviewCompleted],[IsSalesTaxReviewRequired]=S.[IsSalesTaxReviewRequired],[IsVATAssessed]=S.[IsVATAssessed],[LeasePaymentId]=S.[LeasePaymentId],[LineOfCreditId]=S.[LineOfCreditId],[LoanPaymentId]=S.[LoanPaymentId],[NewBillToId]=S.[NewBillToId],[NewCustomerId]=S.[NewCustomerId],[NewLocationId]=S.[NewLocationId],[NewSequenceNumber]=S.[NewSequenceNumber],[OldSequenceNumber]=S.[OldSequenceNumber],[OriginalCustomerId]=S.[OriginalCustomerId],[PostDate]=S.[PostDate],[ReceivableAmendmentType]=S.[ReceivableAmendmentType],[SortOrder]=S.[SortOrder],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssumptionDate],[AssumptionReason],[ContractId],[ContractType],[CreatedById],[CreatedTime],[IsAccountingApproved],[IsAMReviewCompleted],[IsAMReviewRequired],[IsBillInAlternateCurrency],[IsCloneAssetLocation],[IsFundingApproved],[IsSalesLeaseBackReviewCompleted],[IsSalesTaxExemption],[IsSalesTaxReviewCompleted],[IsSalesTaxReviewRequired],[IsVATAssessed],[LeasePaymentId],[LineOfCreditId],[LoanPaymentId],[NewBillToId],[NewCustomerId],[NewLocationId],[NewSequenceNumber],[OldSequenceNumber],[OriginalCustomerId],[PostDate],[ReceivableAmendmentType],[SortOrder],[Status])
    VALUES (S.[AssumptionDate],S.[AssumptionReason],S.[ContractId],S.[ContractType],S.[CreatedById],S.[CreatedTime],S.[IsAccountingApproved],S.[IsAMReviewCompleted],S.[IsAMReviewRequired],S.[IsBillInAlternateCurrency],S.[IsCloneAssetLocation],S.[IsFundingApproved],S.[IsSalesLeaseBackReviewCompleted],S.[IsSalesTaxExemption],S.[IsSalesTaxReviewCompleted],S.[IsSalesTaxReviewRequired],S.[IsVATAssessed],S.[LeasePaymentId],S.[LineOfCreditId],S.[LoanPaymentId],S.[NewBillToId],S.[NewCustomerId],S.[NewLocationId],S.[NewSequenceNumber],S.[OldSequenceNumber],S.[OriginalCustomerId],S.[PostDate],S.[ReceivableAmendmentType],S.[SortOrder],S.[Status])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
