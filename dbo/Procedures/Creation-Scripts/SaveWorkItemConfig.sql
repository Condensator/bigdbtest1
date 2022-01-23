SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveWorkItemConfig]
(
 @val [dbo].[WorkItemConfig] READONLY
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
MERGE [dbo].[WorkItemConfigs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AcquireFromOtherUser]=S.[AcquireFromOtherUser],[AllowTossing]=S.[AllowTossing],[DummyEndStep]=S.[DummyEndStep],[Duration]=S.[Duration],[Form]=S.[Form],[IsActive]=S.[IsActive],[IsNotify]=S.[IsNotify],[IsNotifyOnAssignment]=S.[IsNotifyOnAssignment],[IsOptional]=S.[IsOptional],[IsOwnerUserRequired]=S.[IsOwnerUserRequired],[IsRemovable]=S.[IsRemovable],[IsRemove]=S.[IsRemove],[Label]=S.[Label],[Name]=S.[Name],[OverrideOwnerUser]=S.[OverrideOwnerUser],[TransactionStageConfigId]=S.[TransactionStageConfigId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AcquireFromOtherUser],[AllowTossing],[CreatedById],[CreatedTime],[DummyEndStep],[Duration],[Form],[IsActive],[IsNotify],[IsNotifyOnAssignment],[IsOptional],[IsOwnerUserRequired],[IsRemovable],[IsRemove],[Label],[Name],[OverrideOwnerUser],[TransactionConfigId],[TransactionStageConfigId])
    VALUES (S.[AcquireFromOtherUser],S.[AllowTossing],S.[CreatedById],S.[CreatedTime],S.[DummyEndStep],S.[Duration],S.[Form],S.[IsActive],S.[IsNotify],S.[IsNotifyOnAssignment],S.[IsOptional],S.[IsOwnerUserRequired],S.[IsRemovable],S.[IsRemove],S.[Label],S.[Name],S.[OverrideOwnerUser],S.[TransactionConfigId],S.[TransactionStageConfigId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
