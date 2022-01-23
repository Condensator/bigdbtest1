SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


	CREATE PROC [dbo].[SaveUserPreference]
(
 @val [dbo].[UserPreference] READONLY
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
MERGE [dbo].[UserPreferences] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CommandPath]=S.[CommandPath],[Context]=S.[Context],[IsActive]=S.[IsActive],[IsBookMarked]=S.[IsBookMarked],[IsDefault]=S.[IsDefault],[Name]=S.[Name],[PreferenceKey]=S.[PreferenceKey],[PreferenceValue]=S.[PreferenceValue],[TransactionIdentifier]=S.[TransactionIdentifier],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserId]=S.[UserId]
WHEN NOT MATCHED THEN
	INSERT ([CommandPath],[Context],[CreatedById],[CreatedTime],[IsActive],[IsBookMarked],[IsDefault],[Name],[PreferenceKey],[PreferenceValue],[TransactionIdentifier],[Type],[UserId])
    VALUES (S.[CommandPath],S.[Context],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[IsBookMarked],S.[IsDefault],S.[Name],S.[PreferenceKey],S.[PreferenceValue],S.[TransactionIdentifier],S.[Type],S.[UserId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
