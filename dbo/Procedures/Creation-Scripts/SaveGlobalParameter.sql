SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveGlobalParameter]
(
 @val [dbo].[GlobalParameter] READONLY
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
MERGE [dbo].[GlobalParameters] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Category]=S.[Category],[Description]=S.[Description],[IsActive]=S.[IsActive],[IsSystemDefined]=S.[IsSystemDefined],[Name]=S.[Name],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Value]=S.[Value]
WHEN NOT MATCHED THEN
	INSERT ([Category],[CreatedById],[CreatedTime],[Description],[IsActive],[IsSystemDefined],[Name],[Type],[Value])
    VALUES (S.[Category],S.[CreatedById],S.[CreatedTime],S.[Description],S.[IsActive],S.[IsSystemDefined],S.[Name],S.[Type],S.[Value])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
