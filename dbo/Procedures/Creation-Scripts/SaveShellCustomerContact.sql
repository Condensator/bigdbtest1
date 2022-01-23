SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveShellCustomerContact]
(
 @val [dbo].[ShellCustomerContact] READONLY
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
MERGE [dbo].[ShellCustomerContacts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [DateOfBirth]=S.[DateOfBirth],[EMailId]=S.[EMailId],[ExtensionNumber1]=S.[ExtensionNumber1],[FaxNumber]=S.[FaxNumber],[FirstName]=S.[FirstName],[IsShellCustomerContactCreated]=S.[IsShellCustomerContactCreated],[LastName]=S.[LastName],[LWSystemId]=S.[LWSystemId],[MiddleName]=S.[MiddleName],[MobilePhoneNumber]=S.[MobilePhoneNumber],[PhoneNumber1]=S.[PhoneNumber1],[Prefix]=S.[Prefix],[SFDCContactId]=S.[SFDCContactId],[SocialSecurityNumber]=S.[SocialSecurityNumber],[UniqueIdentifier]=S.[UniqueIdentifier],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[DateOfBirth],[EMailId],[ExtensionNumber1],[FaxNumber],[FirstName],[IsShellCustomerContactCreated],[LastName],[LWSystemId],[MiddleName],[MobilePhoneNumber],[PhoneNumber1],[Prefix],[SFDCContactId],[SocialSecurityNumber],[UniqueIdentifier])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[DateOfBirth],S.[EMailId],S.[ExtensionNumber1],S.[FaxNumber],S.[FirstName],S.[IsShellCustomerContactCreated],S.[LastName],S.[LWSystemId],S.[MiddleName],S.[MobilePhoneNumber],S.[PhoneNumber1],S.[Prefix],S.[SFDCContactId],S.[SocialSecurityNumber],S.[UniqueIdentifier])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
