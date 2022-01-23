SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveOrganizationConfig]
(
 @val [dbo].[OrganizationConfig] READONLY
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
MERGE [dbo].[OrganizationConfigs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BrowserTitle]=S.[BrowserTitle],[ContactMessage]=S.[ContactMessage],[EmailContact]=S.[EmailContact],[FavIcon_Content]=S.[FavIcon_Content],[FavIcon_Source]=S.[FavIcon_Source],[FavIcon_Type]=S.[FavIcon_Type],[FooterLogo_Content]=S.[FooterLogo_Content],[FooterLogo_Source]=S.[FooterLogo_Source],[FooterLogo_Type]=S.[FooterLogo_Type],[IsActive]=S.[IsActive],[LoginBackground_Content]=S.[LoginBackground_Content],[LoginBackground_Source]=S.[LoginBackground_Source],[LoginBackground_Type]=S.[LoginBackground_Type],[LoginLogo_Content]=S.[LoginLogo_Content],[LoginLogo_Source]=S.[LoginLogo_Source],[LoginLogo_Type]=S.[LoginLogo_Type],[LoginTitle]=S.[LoginTitle],[MenuLogo_Content]=S.[MenuLogo_Content],[MenuLogo_Source]=S.[MenuLogo_Source],[MenuLogo_Type]=S.[MenuLogo_Type],[Name]=S.[Name],[TermsAndConditions]=S.[TermsAndConditions],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BrowserTitle],[ContactMessage],[CreatedById],[CreatedTime],[EmailContact],[FavIcon_Content],[FavIcon_Source],[FavIcon_Type],[FooterLogo_Content],[FooterLogo_Source],[FooterLogo_Type],[IsActive],[LoginBackground_Content],[LoginBackground_Source],[LoginBackground_Type],[LoginLogo_Content],[LoginLogo_Source],[LoginLogo_Type],[LoginTitle],[MenuLogo_Content],[MenuLogo_Source],[MenuLogo_Type],[Name],[TermsAndConditions])
    VALUES (S.[BrowserTitle],S.[ContactMessage],S.[CreatedById],S.[CreatedTime],S.[EmailContact],S.[FavIcon_Content],S.[FavIcon_Source],S.[FavIcon_Type],S.[FooterLogo_Content],S.[FooterLogo_Source],S.[FooterLogo_Type],S.[IsActive],S.[LoginBackground_Content],S.[LoginBackground_Source],S.[LoginBackground_Type],S.[LoginLogo_Content],S.[LoginLogo_Source],S.[LoginLogo_Type],S.[LoginTitle],S.[MenuLogo_Content],S.[MenuLogo_Source],S.[MenuLogo_Type],S.[Name],S.[TermsAndConditions])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
