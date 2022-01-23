SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveVendorPortalDashboardNotification]
(
 @val [dbo].[VendorPortalDashboardNotification] READONLY
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
MERGE [dbo].[VendorPortalDashboardNotifications] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Description]=S.[Description],[EntitySummary]=S.[EntitySummary],[SourceType]=S.[SourceType],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VendorId]=S.[VendorId]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[Description],[EntitySummary],[SourceType],[Status],[VendorId])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[Description],S.[EntitySummary],S.[SourceType],S.[Status],S.[VendorId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
