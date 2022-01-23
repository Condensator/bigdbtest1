SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveBusinessUnit]
(
 @val [dbo].[BusinessUnit] READONLY
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
MERGE [dbo].[BusinessUnits] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BusinessCalendarId]=S.[BusinessCalendarId],[BusinessEndTimeInHours]=S.[BusinessEndTimeInHours],[BusinessEndTimeInMinutes]=S.[BusinessEndTimeInMinutes],[BusinessStartTimeInHours]=S.[BusinessStartTimeInHours],[BusinessStartTimeInMinutes]=S.[BusinessStartTimeInMinutes],[CurrentBusinessDate]=S.[CurrentBusinessDate],[CutoffTimeInHours]=S.[CutoffTimeInHours],[CutoffTimeInMinutes]=S.[CutoffTimeInMinutes],[CutoffTimeThresholdInMins]=S.[CutoffTimeThresholdInMins],[ImplementCutoffTime]=S.[ImplementCutoffTime],[IsActive]=S.[IsActive],[IsDefault]=S.[IsDefault],[LatestLoggedOutTime]=S.[LatestLoggedOutTime],[LatestNotifiedTime]=S.[LatestNotifiedTime],[Name]=S.[Name],[PortfolioId]=S.[PortfolioId],[StandardTimeZoneId]=S.[StandardTimeZoneId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BusinessCalendarId],[BusinessEndTimeInHours],[BusinessEndTimeInMinutes],[BusinessStartTimeInHours],[BusinessStartTimeInMinutes],[CreatedById],[CreatedTime],[CurrentBusinessDate],[CutoffTimeInHours],[CutoffTimeInMinutes],[CutoffTimeThresholdInMins],[ImplementCutoffTime],[IsActive],[IsDefault],[LatestLoggedOutTime],[LatestNotifiedTime],[Name],[PortfolioId],[StandardTimeZoneId])
    VALUES (S.[BusinessCalendarId],S.[BusinessEndTimeInHours],S.[BusinessEndTimeInMinutes],S.[BusinessStartTimeInHours],S.[BusinessStartTimeInMinutes],S.[CreatedById],S.[CreatedTime],S.[CurrentBusinessDate],S.[CutoffTimeInHours],S.[CutoffTimeInMinutes],S.[CutoffTimeThresholdInMins],S.[ImplementCutoffTime],S.[IsActive],S.[IsDefault],S.[LatestLoggedOutTime],S.[LatestNotifiedTime],S.[Name],S.[PortfolioId],S.[StandardTimeZoneId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
