SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveTimeZone]
(
 @val [dbo].[TimeZone] READONLY
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
MERGE [dbo].[TimeZones] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Abbreviation]=S.[Abbreviation],[Name]=S.[Name],[StandardZoneId]=S.[StandardZoneId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Zone]=S.[Zone]
WHEN NOT MATCHED THEN
	INSERT ([Abbreviation],[CreatedById],[CreatedTime],[Name],[StandardZoneId],[Zone])
    VALUES (S.[Abbreviation],S.[CreatedById],S.[CreatedTime],S.[Name],S.[StandardZoneId],S.[Zone])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
