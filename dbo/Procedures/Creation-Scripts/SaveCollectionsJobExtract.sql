SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCollectionsJobExtract]
(
 @val [dbo].[CollectionsJobExtract] READONLY
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
MERGE [dbo].[CollectionsJobExtracts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AcrossQueue]=S.[AcrossQueue],[AllocatedQueueId]=S.[AllocatedQueueId],[BusinessUnitId]=S.[BusinessUnitId],[ContractId]=S.[ContractId],[CurrencyId]=S.[CurrencyId],[CustomerId]=S.[CustomerId],[IsWorkListCreated]=S.[IsWorkListCreated],[IsWorkListIdentified]=S.[IsWorkListIdentified],[IsWorkListUnassigned]=S.[IsWorkListUnassigned],[JobStepInstanceId]=S.[JobStepInstanceId],[PreviousQueueId]=S.[PreviousQueueId],[PreviousWorkListDetailId]=S.[PreviousWorkListDetailId],[PreviousWorkListId]=S.[PreviousWorkListId],[PrimaryCollectorId]=S.[PrimaryCollectorId],[RemitToId]=S.[RemitToId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AcrossQueue],[AllocatedQueueId],[BusinessUnitId],[ContractId],[CreatedById],[CreatedTime],[CurrencyId],[CustomerId],[IsWorkListCreated],[IsWorkListIdentified],[IsWorkListUnassigned],[JobStepInstanceId],[PreviousQueueId],[PreviousWorkListDetailId],[PreviousWorkListId],[PrimaryCollectorId],[RemitToId])
    VALUES (S.[AcrossQueue],S.[AllocatedQueueId],S.[BusinessUnitId],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[CustomerId],S.[IsWorkListCreated],S.[IsWorkListIdentified],S.[IsWorkListUnassigned],S.[JobStepInstanceId],S.[PreviousQueueId],S.[PreviousWorkListDetailId],S.[PreviousWorkListId],S.[PrimaryCollectorId],S.[RemitToId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
