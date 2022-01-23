SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAutoPayoffContract]
(
 @val [dbo].[AutoPayoffContract] READONLY
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
MERGE [dbo].[AutoPayoffContracts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AutoPayoffTemplateId]=S.[AutoPayoffTemplateId],[ContractId]=S.[ContractId],[IsActive]=S.[IsActive],[IsProcessed]=S.[IsProcessed],[JobStepInstanceId]=S.[JobStepInstanceId],[PayoffEffectiveDate]=S.[PayoffEffectiveDate],[TaskChunkServiceInstanceId]=S.[TaskChunkServiceInstanceId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AutoPayoffTemplateId],[ContractId],[CreatedById],[CreatedTime],[IsActive],[IsProcessed],[JobStepInstanceId],[PayoffEffectiveDate],[TaskChunkServiceInstanceId])
    VALUES (S.[AutoPayoffTemplateId],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[IsProcessed],S.[JobStepInstanceId],S.[PayoffEffectiveDate],S.[TaskChunkServiceInstanceId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
