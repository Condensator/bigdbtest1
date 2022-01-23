SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveParty]
(
 @val [dbo].[Party] READONLY
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
MERGE [dbo].[Parties] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Alias]=S.[Alias],[CompanyName]=S.[CompanyName],[CreationDate]=S.[CreationDate],[CurrentRole]=S.[CurrentRole],[CustomerLegalStatusId]=S.[CustomerLegalStatusId],[DateOfBirth]=S.[DateOfBirth],[DateofIssue]=S.[DateofIssue],[DateofIssueID]=S.[DateofIssueID],[DoingBusinessAs]=S.[DoingBusinessAs],[EIKNumber_CT]=S.[EIKNumber_CT],[Email]=S.[Email],[EquityOwnerEGN1]=S.[EquityOwnerEGN1],[EquityOwnerEGN2]=S.[EquityOwnerEGN2],[EquityOwnerEGN3]=S.[EquityOwnerEGN3],[ExternalPartyNumber]=S.[ExternalPartyNumber],[FirstName]=S.[FirstName],[Gender]=S.[Gender],[IncorporationDate]=S.[IncorporationDate],[IsCorporate]=S.[IsCorporate],[IsForeigner]=S.[IsForeigner],[IsIntercompany]=S.[IsIntercompany],[IsSoleProprietor]=S.[IsSoleProprietor],[IsSpecialClient]=S.[IsSpecialClient],[IssuedIn]=S.[IssuedIn],[IsVATRegistration]=S.[IsVATRegistration],[LanguageId]=S.[LanguageId],[LastFourDigitUniqueIdentificationNumber]=S.[LastFourDigitUniqueIdentificationNumber],[LastName]=S.[LastName],[Ln4]=S.[Ln4],[MiddleName]=S.[MiddleName],[NationalIdCardNumber_CT]=S.[NationalIdCardNumber_CT],[ParentPartyId]=S.[ParentPartyId],[PartyEntityType]=S.[PartyEntityType],[PartyName]=S.[PartyName],[PartyNumber]=S.[PartyNumber],[PassportAddress]=S.[PassportAddress],[PassportCountry]=S.[PassportCountry],[PassportNo]=S.[PassportNo],[PortfolioId]=S.[PortfolioId],[ProfessionsId]=S.[ProfessionsId],[Representative1]=S.[Representative1],[Representative2]=S.[Representative2],[Representative3]=S.[Representative3],[SectorId]=S.[SectorId],[StateOfIncorporationId]=S.[StateOfIncorporationId],[Suffix]=S.[Suffix],[UniqueIdentificationNumber_CT]=S.[UniqueIdentificationNumber_CT],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VATRegistration]=S.[VATRegistration],[VATRegistrationNumber]=S.[VATRegistrationNumber],[WayOfRepresentation]=S.[WayOfRepresentation]
WHEN NOT MATCHED THEN
	INSERT ([Alias],[CompanyName],[CreatedById],[CreatedTime],[CreationDate],[CurrentRole],[CustomerLegalStatusId],[DateOfBirth],[DateofIssue],[DateofIssueID],[DoingBusinessAs],[EIKNumber_CT],[Email],[EquityOwnerEGN1],[EquityOwnerEGN2],[EquityOwnerEGN3],[ExternalPartyNumber],[FirstName],[Gender],[IncorporationDate],[IsCorporate],[IsForeigner],[IsIntercompany],[IsSoleProprietor],[IsSpecialClient],[IssuedIn],[IsVATRegistration],[LanguageId],[LastFourDigitUniqueIdentificationNumber],[LastName],[Ln4],[MiddleName],[NationalIdCardNumber_CT],[ParentPartyId],[PartyEntityType],[PartyName],[PartyNumber],[PassportAddress],[PassportCountry],[PassportNo],[PortfolioId],[ProfessionsId],[Representative1],[Representative2],[Representative3],[SectorId],[StateOfIncorporationId],[Suffix],[UniqueIdentificationNumber_CT],[VATRegistration],[VATRegistrationNumber],[WayOfRepresentation])
    VALUES (S.[Alias],S.[CompanyName],S.[CreatedById],S.[CreatedTime],S.[CreationDate],S.[CurrentRole],S.[CustomerLegalStatusId],S.[DateOfBirth],S.[DateofIssue],S.[DateofIssueID],S.[DoingBusinessAs],S.[EIKNumber_CT],S.[Email],S.[EquityOwnerEGN1],S.[EquityOwnerEGN2],S.[EquityOwnerEGN3],S.[ExternalPartyNumber],S.[FirstName],S.[Gender],S.[IncorporationDate],S.[IsCorporate],S.[IsForeigner],S.[IsIntercompany],S.[IsSoleProprietor],S.[IsSpecialClient],S.[IssuedIn],S.[IsVATRegistration],S.[LanguageId],S.[LastFourDigitUniqueIdentificationNumber],S.[LastName],S.[Ln4],S.[MiddleName],S.[NationalIdCardNumber_CT],S.[ParentPartyId],S.[PartyEntityType],S.[PartyName],S.[PartyNumber],S.[PassportAddress],S.[PassportCountry],S.[PassportNo],S.[PortfolioId],S.[ProfessionsId],S.[Representative1],S.[Representative2],S.[Representative3],S.[SectorId],S.[StateOfIncorporationId],S.[Suffix],S.[UniqueIdentificationNumber_CT],S.[VATRegistration],S.[VATRegistrationNumber],S.[WayOfRepresentation])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
