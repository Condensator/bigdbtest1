SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveSundryRecurringJobExtract]
(
 @val [dbo].[SundryRecurringJobExtract] READONLY
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
MERGE [dbo].[SundryRecurringJobExtracts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ComputedProcessThroughDate]=S.[ComputedProcessThroughDate],[ContractId]=S.[ContractId],[EntityType]=S.[EntityType],[FunderId]=S.[FunderId],[IsAdvance]=S.[IsAdvance],[IsSubmitted]=S.[IsSubmitted],[IsSyndicated]=S.[IsSyndicated],[JobStepInstanceId]=S.[JobStepInstanceId],[LastExtensionARUpdateRunDate]=S.[LastExtensionARUpdateRunDate],[SundryRecurringId]=S.[SundryRecurringId],[TaskChunkServiceInstanceId]=S.[TaskChunkServiceInstanceId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ComputedProcessThroughDate],[ContractId],[CreatedById],[CreatedTime],[EntityType],[FunderId],[IsAdvance],[IsSubmitted],[IsSyndicated],[JobStepInstanceId],[LastExtensionARUpdateRunDate],[SundryRecurringId],[TaskChunkServiceInstanceId])
    VALUES (S.[ComputedProcessThroughDate],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[EntityType],S.[FunderId],S.[IsAdvance],S.[IsSubmitted],S.[IsSyndicated],S.[JobStepInstanceId],S.[LastExtensionARUpdateRunDate],S.[SundryRecurringId],S.[TaskChunkServiceInstanceId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
