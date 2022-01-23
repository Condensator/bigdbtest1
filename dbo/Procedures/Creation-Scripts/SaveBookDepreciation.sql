SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveBookDepreciation]
(
 @val [dbo].[BookDepreciation] READONLY
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
MERGE [dbo].[BookDepreciations] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[BeginDate]=S.[BeginDate],[BookDepreciationTemplateId]=S.[BookDepreciationTemplateId],[BranchId]=S.[BranchId],[ClearAccumulatedGLJournalId]=S.[ClearAccumulatedGLJournalId],[ContractId]=S.[ContractId],[CostBasis_Amount]=S.[CostBasis_Amount],[CostBasis_Currency]=S.[CostBasis_Currency],[CostCenterId]=S.[CostCenterId],[EndDate]=S.[EndDate],[GLTemplateId]=S.[GLTemplateId],[InstrumentTypeId]=S.[InstrumentTypeId],[IsActive]=S.[IsActive],[IsInOTP]=S.[IsInOTP],[IsLeaseComponent]=S.[IsLeaseComponent],[IsLessorOwned]=S.[IsLessorOwned],[LastAmortRunDate]=S.[LastAmortRunDate],[LineofBusinessId]=S.[LineofBusinessId],[PerDayDepreciationFactor]=S.[PerDayDepreciationFactor],[RemainingLifeInMonths]=S.[RemainingLifeInMonths],[ReversalPostDate]=S.[ReversalPostDate],[Salvage_Amount]=S.[Salvage_Amount],[Salvage_Currency]=S.[Salvage_Currency],[TerminatedDate]=S.[TerminatedDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[BeginDate],[BookDepreciationTemplateId],[BranchId],[ClearAccumulatedGLJournalId],[ContractId],[CostBasis_Amount],[CostBasis_Currency],[CostCenterId],[CreatedById],[CreatedTime],[EndDate],[GLTemplateId],[InstrumentTypeId],[IsActive],[IsInOTP],[IsLeaseComponent],[IsLessorOwned],[LastAmortRunDate],[LineofBusinessId],[PerDayDepreciationFactor],[RemainingLifeInMonths],[ReversalPostDate],[Salvage_Amount],[Salvage_Currency],[TerminatedDate])
    VALUES (S.[AssetId],S.[BeginDate],S.[BookDepreciationTemplateId],S.[BranchId],S.[ClearAccumulatedGLJournalId],S.[ContractId],S.[CostBasis_Amount],S.[CostBasis_Currency],S.[CostCenterId],S.[CreatedById],S.[CreatedTime],S.[EndDate],S.[GLTemplateId],S.[InstrumentTypeId],S.[IsActive],S.[IsInOTP],S.[IsLeaseComponent],S.[IsLessorOwned],S.[LastAmortRunDate],S.[LineofBusinessId],S.[PerDayDepreciationFactor],S.[RemainingLifeInMonths],S.[ReversalPostDate],S.[Salvage_Amount],S.[Salvage_Currency],S.[TerminatedDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
