SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLeveragedLeaseContractOption]
(
 @val [dbo].[LeveragedLeaseContractOption] READONLY
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
MERGE [dbo].[LeveragedLeaseContractOptions] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ContractOption]=S.[ContractOption],[ContractOptionTerms]=S.[ContractOptionTerms],[IsActive]=S.[IsActive],[IsAnyDay]=S.[IsAnyDay],[IsEarly]=S.[IsEarly],[IsExcluded]=S.[IsExcluded],[IsPartialPermitted]=S.[IsPartialPermitted],[IsRenewalOfferApproved]=S.[IsRenewalOfferApproved],[LesseeNoticeDays]=S.[LesseeNoticeDays],[OptionDate]=S.[OptionDate],[Penalty]=S.[Penalty],[PurchaseFactor]=S.[PurchaseFactor],[RenewalFactor]=S.[RenewalFactor],[RestockingFee]=S.[RestockingFee],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ContractOption],[ContractOptionTerms],[CreatedById],[CreatedTime],[IsActive],[IsAnyDay],[IsEarly],[IsExcluded],[IsPartialPermitted],[IsRenewalOfferApproved],[LesseeNoticeDays],[LeveragedLeaseId],[OptionDate],[Penalty],[PurchaseFactor],[RenewalFactor],[RestockingFee])
    VALUES (S.[ContractOption],S.[ContractOptionTerms],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[IsAnyDay],S.[IsEarly],S.[IsExcluded],S.[IsPartialPermitted],S.[IsRenewalOfferApproved],S.[LesseeNoticeDays],S.[LeveragedLeaseId],S.[OptionDate],S.[Penalty],S.[PurchaseFactor],S.[RenewalFactor],S.[RestockingFee])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
