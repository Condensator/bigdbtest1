SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveShellCustomerDetail]
(
 @val [dbo].[ShellCustomerDetail] READONLY
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
MERGE [dbo].[ShellCustomerDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ApprovedExchangeId]=S.[ApprovedExchangeId],[ApprovedRegulatorId]=S.[ApprovedRegulatorId],[BusinessTypeId]=S.[BusinessTypeId],[BusinessTypeNAICSCodeId]=S.[BusinessTypeNAICSCodeId],[CIPDocumentSourceForName]=S.[CIPDocumentSourceForName],[CIPDocumentSourceNameId]=S.[CIPDocumentSourceNameId],[CompanyName]=S.[CompanyName],[DateOfBirth]=S.[DateOfBirth],[FirstName]=S.[FirstName],[IncomeTaxStatus]=S.[IncomeTaxStatus],[IsCorporate]=S.[IsCorporate],[IsShellCustomerCreated]=S.[IsShellCustomerCreated],[IsSoleProprietor]=S.[IsSoleProprietor],[JurisdictionOfSovereignId]=S.[JurisdictionOfSovereignId],[LastName]=S.[LastName],[LegalNameValidationDate]=S.[LegalNameValidationDate],[MiddleName]=S.[MiddleName],[PartyType]=S.[PartyType],[PercentageOfGovernmentOwnership]=S.[PercentageOfGovernmentOwnership],[SFDCId]=S.[SFDCId],[StateOfIncorporationId]=S.[StateOfIncorporationId],[Status]=S.[Status],[UniqueIdentificationNumber]=S.[UniqueIdentificationNumber],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ApprovedExchangeId],[ApprovedRegulatorId],[BusinessTypeId],[BusinessTypeNAICSCodeId],[CIPDocumentSourceForName],[CIPDocumentSourceNameId],[CompanyName],[CreatedById],[CreatedTime],[DateOfBirth],[FirstName],[IncomeTaxStatus],[IsCorporate],[IsShellCustomerCreated],[IsSoleProprietor],[JurisdictionOfSovereignId],[LastName],[LegalNameValidationDate],[MiddleName],[PartyType],[PercentageOfGovernmentOwnership],[SFDCId],[StateOfIncorporationId],[Status],[UniqueIdentificationNumber])
    VALUES (S.[ApprovedExchangeId],S.[ApprovedRegulatorId],S.[BusinessTypeId],S.[BusinessTypeNAICSCodeId],S.[CIPDocumentSourceForName],S.[CIPDocumentSourceNameId],S.[CompanyName],S.[CreatedById],S.[CreatedTime],S.[DateOfBirth],S.[FirstName],S.[IncomeTaxStatus],S.[IsCorporate],S.[IsShellCustomerCreated],S.[IsSoleProprietor],S.[JurisdictionOfSovereignId],S.[LastName],S.[LegalNameValidationDate],S.[MiddleName],S.[PartyType],S.[PercentageOfGovernmentOwnership],S.[SFDCId],S.[StateOfIncorporationId],S.[Status],S.[UniqueIdentificationNumber])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
