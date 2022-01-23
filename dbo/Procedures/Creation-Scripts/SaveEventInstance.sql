SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveEventInstance]
(
 @val [dbo].[EventInstance] READONLY
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
MERGE [dbo].[EventInstances] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BusinessUnitId]=S.[BusinessUnitId],[CorrelationId]=S.[CorrelationId],[EntityId]=S.[EntityId],[EntityName]=S.[EntityName],[EntitySummary]=S.[EntitySummary],[EventArg]=S.[EventArg],[EventConfigId]=S.[EventConfigId],[IsExternalCall]=S.[IsExternalCall],[IsMigrationCall]=S.[IsMigrationCall],[IsWebServiceCall]=S.[IsWebServiceCall],[JobServiceId]=S.[JobServiceId],[Status]=S.[Status],[SubmittedUserId]=S.[SubmittedUserId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BusinessUnitId],[CorrelationId],[CreatedById],[CreatedTime],[EntityId],[EntityName],[EntitySummary],[EventArg],[EventConfigId],[IsExternalCall],[IsMigrationCall],[IsWebServiceCall],[JobServiceId],[Status],[SubmittedUserId])
    VALUES (S.[BusinessUnitId],S.[CorrelationId],S.[CreatedById],S.[CreatedTime],S.[EntityId],S.[EntityName],S.[EntitySummary],S.[EventArg],S.[EventConfigId],S.[IsExternalCall],S.[IsMigrationCall],S.[IsWebServiceCall],S.[JobServiceId],S.[Status],S.[SubmittedUserId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
