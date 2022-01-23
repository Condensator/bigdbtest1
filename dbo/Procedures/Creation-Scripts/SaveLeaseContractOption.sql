SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLeaseContractOption]
(
 @val [dbo].[LeaseContractOption] READONLY
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
MERGE [dbo].[LeaseContractOptions] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[ContractOption]=S.[ContractOption],[ContractOptionTerms]=S.[ContractOptionTerms],[IsActive]=S.[IsActive],[IsAnyDay]=S.[IsAnyDay],[IsEarly]=S.[IsEarly],[IsExcluded]=S.[IsExcluded],[IsLesseeReasonablyCertainToExerciseOption]=S.[IsLesseeReasonablyCertainToExerciseOption],[IsOptionControlledByLessor]=S.[IsOptionControlledByLessor],[IsPartialPermitted]=S.[IsPartialPermitted],[IsRenewalOfferApproved]=S.[IsRenewalOfferApproved],[LesseeNoticeDays]=S.[LesseeNoticeDays],[OptionDate]=S.[OptionDate],[OptionMonth]=S.[OptionMonth],[Penalty]=S.[Penalty],[PurchaseFactor]=S.[PurchaseFactor],[RenewalFactor]=S.[RenewalFactor],[RestockingFee]=S.[RestockingFee],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[ContractOption],[ContractOptionTerms],[CreatedById],[CreatedTime],[IsActive],[IsAnyDay],[IsEarly],[IsExcluded],[IsLesseeReasonablyCertainToExerciseOption],[IsOptionControlledByLessor],[IsPartialPermitted],[IsRenewalOfferApproved],[LeaseFinanceId],[LesseeNoticeDays],[OptionDate],[OptionMonth],[Penalty],[PurchaseFactor],[RenewalFactor],[RestockingFee])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[ContractOption],S.[ContractOptionTerms],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[IsAnyDay],S.[IsEarly],S.[IsExcluded],S.[IsLesseeReasonablyCertainToExerciseOption],S.[IsOptionControlledByLessor],S.[IsPartialPermitted],S.[IsRenewalOfferApproved],S.[LeaseFinanceId],S.[LesseeNoticeDays],S.[OptionDate],S.[OptionMonth],S.[Penalty],S.[PurchaseFactor],S.[RenewalFactor],S.[RestockingFee])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
