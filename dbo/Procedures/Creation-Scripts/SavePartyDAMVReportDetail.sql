SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePartyDAMVReportDetail]
(
 @val [dbo].[PartyDAMVReportDetail] READONLY
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
MERGE [dbo].[PartyDAMVReportDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BirthPlaceCountryCode]=S.[BirthPlaceCountryCode],[BirthPlaceCountryName]=S.[BirthPlaceCountryName],[BirthPlaceCountryNameLatin]=S.[BirthPlaceCountryNameLatin],[BirthPlaceDistrictName]=S.[BirthPlaceDistrictName],[BirthPlaceMunicipalityName]=S.[BirthPlaceMunicipalityName],[BirthPlaceTerritorialUnitName]=S.[BirthPlaceTerritorialUnitName],[DAIntegrationResponseId]=S.[DAIntegrationResponseId],[DateOfBirth]=S.[DateOfBirth],[DocumentType]=S.[DocumentType],[DocumentTypeLatin]=S.[DocumentTypeLatin],[FirstName]=S.[FirstName],[IdentityDocumentNumber]=S.[IdentityDocumentNumber],[IssueDate]=S.[IssueDate],[IssuerName]=S.[IssuerName],[IssuerNameLatin]=S.[IssuerNameLatin],[IssuerPlace]=S.[IssuerPlace],[IssuerPlaceLatin]=S.[IssuerPlaceLatin],[LastName]=S.[LastName],[MiddleName]=S.[MiddleName],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[ValidDate]=S.[ValidDate]
WHEN NOT MATCHED THEN
	INSERT ([BirthPlaceCountryCode],[BirthPlaceCountryName],[BirthPlaceCountryNameLatin],[BirthPlaceDistrictName],[BirthPlaceMunicipalityName],[BirthPlaceTerritorialUnitName],[CreatedById],[CreatedTime],[DAIntegrationResponseId],[DateOfBirth],[DocumentType],[DocumentTypeLatin],[FirstName],[Id],[IdentityDocumentNumber],[IssueDate],[IssuerName],[IssuerNameLatin],[IssuerPlace],[IssuerPlaceLatin],[LastName],[MiddleName],[ValidDate])
    VALUES (S.[BirthPlaceCountryCode],S.[BirthPlaceCountryName],S.[BirthPlaceCountryNameLatin],S.[BirthPlaceDistrictName],S.[BirthPlaceMunicipalityName],S.[BirthPlaceTerritorialUnitName],S.[CreatedById],S.[CreatedTime],S.[DAIntegrationResponseId],S.[DateOfBirth],S.[DocumentType],S.[DocumentTypeLatin],S.[FirstName],S.[Id],S.[IdentityDocumentNumber],S.[IssueDate],S.[IssuerName],S.[IssuerNameLatin],S.[IssuerPlace],S.[IssuerPlaceLatin],S.[LastName],S.[MiddleName],S.[ValidDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
