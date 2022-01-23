SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLicenseToken]
(
 @val [dbo].[LicenseToken] READONLY
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
MERGE [dbo].[LicenseTokens] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CompanyName]=S.[CompanyName],[Excluded]=S.[Excluded],[IsReadOnly]=S.[IsReadOnly],[LoginAuditId]=S.[LoginAuditId],[TokenKey]=S.[TokenKey],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserId]=S.[UserId]
WHEN NOT MATCHED THEN
	INSERT ([CompanyName],[CreatedById],[CreatedTime],[Excluded],[IsReadOnly],[LoginAuditId],[TokenKey],[UserId])
    VALUES (S.[CompanyName],S.[CreatedById],S.[CreatedTime],S.[Excluded],S.[IsReadOnly],S.[LoginAuditId],S.[TokenKey],S.[UserId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
