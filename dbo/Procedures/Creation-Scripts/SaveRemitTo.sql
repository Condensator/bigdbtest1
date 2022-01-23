SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveRemitTo]
(
 @val [dbo].[RemitTo] READONLY
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
MERGE [dbo].[RemitToes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActivationDate]=S.[ActivationDate],[Code]=S.[Code],[DeactivationDate]=S.[DeactivationDate],[DefaultFromEmail]=S.[DefaultFromEmail],[Description]=S.[Description],[InvoiceComment]=S.[InvoiceComment],[InvoiceFooterText]=S.[InvoiceFooterText],[IsActive]=S.[IsActive],[IsPrivateLabel]=S.[IsPrivateLabel],[IsSecuredParty]=S.[IsSecuredParty],[LegalEntityAddressId]=S.[LegalEntityAddressId],[LegalEntityContactId]=S.[LegalEntityContactId],[LogoId]=S.[LogoId],[Name]=S.[Name],[PartyAddressId]=S.[PartyAddressId],[PartyContactId]=S.[PartyContactId],[PortfolioId]=S.[PortfolioId],[ReceiptType]=S.[ReceiptType],[UniqueIdentifier]=S.[UniqueIdentifier],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserGroupId]=S.[UserGroupId],[WireType]=S.[WireType]
WHEN NOT MATCHED THEN
	INSERT ([ActivationDate],[Code],[CreatedById],[CreatedTime],[DeactivationDate],[DefaultFromEmail],[Description],[InvoiceComment],[InvoiceFooterText],[IsActive],[IsPrivateLabel],[IsSecuredParty],[LegalEntityAddressId],[LegalEntityContactId],[LogoId],[Name],[PartyAddressId],[PartyContactId],[PortfolioId],[ReceiptType],[UniqueIdentifier],[UserGroupId],[WireType])
    VALUES (S.[ActivationDate],S.[Code],S.[CreatedById],S.[CreatedTime],S.[DeactivationDate],S.[DefaultFromEmail],S.[Description],S.[InvoiceComment],S.[InvoiceFooterText],S.[IsActive],S.[IsPrivateLabel],S.[IsSecuredParty],S.[LegalEntityAddressId],S.[LegalEntityContactId],S.[LogoId],S.[Name],S.[PartyAddressId],S.[PartyContactId],S.[PortfolioId],S.[ReceiptType],S.[UniqueIdentifier],S.[UserGroupId],S.[WireType])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
