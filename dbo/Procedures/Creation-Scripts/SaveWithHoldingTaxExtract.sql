SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveWithHoldingTaxExtract]
(
 @val [dbo].[WithHoldingTaxExtract] READONLY
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
MERGE [dbo].[WithHoldingTaxExtracts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [EntityId]=S.[EntityId],[EntityType]=S.[EntityType],[IsSubmitted]=S.[IsSubmitted],[JobStepInstanceId]=S.[JobStepInstanceId],[ReceivableId]=S.[ReceivableId],[TaskChunkServiceInstanceId]=S.[TaskChunkServiceInstanceId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[EntityId],[EntityType],[IsSubmitted],[JobStepInstanceId],[ReceivableId],[TaskChunkServiceInstanceId])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[EntityId],S.[EntityType],S.[IsSubmitted],S.[JobStepInstanceId],S.[ReceivableId],S.[TaskChunkServiceInstanceId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
