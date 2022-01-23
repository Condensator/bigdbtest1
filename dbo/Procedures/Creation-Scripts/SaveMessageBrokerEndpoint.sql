SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveMessageBrokerEndpoint]
(
 @val [dbo].[MessageBrokerEndpoint] READONLY
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
MERGE [dbo].[MessageBrokerEndpoints] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ComponentName]=S.[ComponentName],[ConnectionConfig]=S.[ConnectionConfig],[Direction]=S.[Direction],[IsActive]=S.[IsActive],[Name]=S.[Name],[QueueType]=S.[QueueType],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ComponentName],[ConnectionConfig],[CreatedById],[CreatedTime],[Direction],[IsActive],[Name],[QueueType],[Type])
    VALUES (S.[ComponentName],S.[ConnectionConfig],S.[CreatedById],S.[CreatedTime],S.[Direction],S.[IsActive],S.[Name],S.[QueueType],S.[Type])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
