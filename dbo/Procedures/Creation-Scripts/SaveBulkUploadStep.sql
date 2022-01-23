SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveBulkUploadStep]
(
 @val [dbo].[BulkUploadStep] READONLY
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
MERGE [dbo].[BulkUploadSteps] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Entity]=S.[Entity],[IsActive]=S.[IsActive],[ProcessingOrder]=S.[ProcessingOrder],[ScenarioConfigId]=S.[ScenarioConfigId],[Transaction]=S.[Transaction],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BulkUploadProfileId],[CreatedById],[CreatedTime],[Entity],[IsActive],[ProcessingOrder],[ScenarioConfigId],[Transaction],[Type])
    VALUES (S.[BulkUploadProfileId],S.[CreatedById],S.[CreatedTime],S.[Entity],S.[IsActive],S.[ProcessingOrder],S.[ScenarioConfigId],S.[Transaction],S.[Type])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
