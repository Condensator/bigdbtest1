SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLegalEntityContact]
(
 @val [dbo].[LegalEntityContact] READONLY
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
MERGE [dbo].[LegalEntityContacts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Description]=S.[Description],[EMailId]=S.[EMailId],[ExtensionNumber1]=S.[ExtensionNumber1],[ExtensionNumber2]=S.[ExtensionNumber2],[FaxNumber]=S.[FaxNumber],[FirstName]=S.[FirstName],[FullName]=S.[FullName],[IsActive]=S.[IsActive],[LastName]=S.[LastName],[LastName2]=S.[LastName2],[MailingAddressId]=S.[MailingAddressId],[MiddleName]=S.[MiddleName],[MobilePhoneNumber]=S.[MobilePhoneNumber],[PhoneNumber1]=S.[PhoneNumber1],[PhoneNumber2]=S.[PhoneNumber2],[Prefix]=S.[Prefix],[UniqueIdentifier]=S.[UniqueIdentifier],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[Description],[EMailId],[ExtensionNumber1],[ExtensionNumber2],[FaxNumber],[FirstName],[FullName],[IsActive],[LastName],[LastName2],[LegalEntityId],[MailingAddressId],[MiddleName],[MobilePhoneNumber],[PhoneNumber1],[PhoneNumber2],[Prefix],[UniqueIdentifier])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[Description],S.[EMailId],S.[ExtensionNumber1],S.[ExtensionNumber2],S.[FaxNumber],S.[FirstName],S.[FullName],S.[IsActive],S.[LastName],S.[LastName2],S.[LegalEntityId],S.[MailingAddressId],S.[MiddleName],S.[MobilePhoneNumber],S.[PhoneNumber1],S.[PhoneNumber2],S.[Prefix],S.[UniqueIdentifier])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
