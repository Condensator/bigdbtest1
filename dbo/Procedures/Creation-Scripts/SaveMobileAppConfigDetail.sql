SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveMobileAppConfigDetail]
(
 @val [dbo].[MobileAppConfigDetail] READONLY
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
MERGE [dbo].[MobileAppConfigDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [DashboardFormName]=S.[DashboardFormName],[IsActive]=S.[IsActive],[IsSupported]=S.[IsSupported],[PrimaryLogo_Content]=S.[PrimaryLogo_Content],[PrimaryLogo_Source]=S.[PrimaryLogo_Source],[PrimaryLogo_Type]=S.[PrimaryLogo_Type],[SecondaryLogo_Content]=S.[SecondaryLogo_Content],[SecondaryLogo_Source]=S.[SecondaryLogo_Source],[SecondaryLogo_Type]=S.[SecondaryLogo_Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Version]=S.[Version]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[DashboardFormName],[IsActive],[IsSupported],[MobileAppConfigId],[PrimaryLogo_Content],[PrimaryLogo_Source],[PrimaryLogo_Type],[SecondaryLogo_Content],[SecondaryLogo_Source],[SecondaryLogo_Type],[Version])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[DashboardFormName],S.[IsActive],S.[IsSupported],S.[MobileAppConfigId],S.[PrimaryLogo_Content],S.[PrimaryLogo_Source],S.[PrimaryLogo_Type],S.[SecondaryLogo_Content],S.[SecondaryLogo_Source],S.[SecondaryLogo_Type],S.[Version])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
