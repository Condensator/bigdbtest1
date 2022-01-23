SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDashboardProfile]
(
 @val [dbo].[DashboardProfile] READONLY
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
MERGE [dbo].[DashboardProfiles] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActivationDate]=S.[ActivationDate],[BannerImage_Content]=S.[BannerImage_Content],[BannerImage_Source]=S.[BannerImage_Source],[BannerImage_Type]=S.[BannerImage_Type],[DeactivationDate]=S.[DeactivationDate],[Description]=S.[Description],[IsActive]=S.[IsActive],[IsDefault]=S.[IsDefault],[IsDisplayAttachment]=S.[IsDisplayAttachment],[IsDisplayDetail]=S.[IsDisplayDetail],[IsDisplaySalesRepInfo]=S.[IsDisplaySalesRepInfo],[Name]=S.[Name],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ActivationDate],[BannerImage_Content],[BannerImage_Source],[BannerImage_Type],[CreatedById],[CreatedTime],[DeactivationDate],[Description],[IsActive],[IsDefault],[IsDisplayAttachment],[IsDisplayDetail],[IsDisplaySalesRepInfo],[Name])
    VALUES (S.[ActivationDate],S.[BannerImage_Content],S.[BannerImage_Source],S.[BannerImage_Type],S.[CreatedById],S.[CreatedTime],S.[DeactivationDate],S.[Description],S.[IsActive],S.[IsDefault],S.[IsDisplayAttachment],S.[IsDisplayDetail],S.[IsDisplaySalesRepInfo],S.[Name])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
