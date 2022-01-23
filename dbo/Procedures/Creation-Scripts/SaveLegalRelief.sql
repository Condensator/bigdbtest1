SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLegalRelief]
(
 @val [dbo].[LegalRelief] READONLY
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
MERGE [dbo].[LegalReliefs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Active]=S.[Active],[Address1]=S.[Address1],[Address2]=S.[Address2],[AddressLine3]=S.[AddressLine3],[Attorney]=S.[Attorney],[BankruptcyNoticeNumber]=S.[BankruptcyNoticeNumber],[BarDate]=S.[BarDate],[CellPhone]=S.[CellPhone],[City]=S.[City],[ConfirmationDate]=S.[ConfirmationDate],[ConversionDate]=S.[ConversionDate],[CourtId]=S.[CourtId],[CustomerId]=S.[CustomerId],[DebtorinPossession]=S.[DebtorinPossession],[DebtorNotes]=S.[DebtorNotes],[DischargeDate]=S.[DischargeDate],[DismissalDate]=S.[DismissalDate],[EMailId]=S.[EMailId],[FaxNumber]=S.[FaxNumber],[FilingDate]=S.[FilingDate],[FundsReceived_Amount]=S.[FundsReceived_Amount],[FundsReceived_Currency]=S.[FundsReceived_Currency],[LegalReliefRecordNumber]=S.[LegalReliefRecordNumber],[LegalReliefType]=S.[LegalReliefType],[Neighborhood]=S.[Neighborhood],[Notes]=S.[Notes],[OfficePhone]=S.[OfficePhone],[PartyContactId]=S.[PartyContactId],[PlacedwithOutsideCounsel]=S.[PlacedwithOutsideCounsel],[POCDeadlineDate]=S.[POCDeadlineDate],[ReaffirmationDate]=S.[ReaffirmationDate],[ReceiverDirectPhone]=S.[ReceiverDirectPhone],[ReceiverEmailId]=S.[ReceiverEmailId],[ReceiverName]=S.[ReceiverName],[ReceiverOfficePhone]=S.[ReceiverOfficePhone],[StateCourtDistrict]=S.[StateCourtDistrict],[StateId]=S.[StateId],[Status]=S.[Status],[SubdivisionOrMunicipality]=S.[SubdivisionOrMunicipality],[TrusteeAppointed]=S.[TrusteeAppointed],[TrusteeName]=S.[TrusteeName],[TrusteeNotes]=S.[TrusteeNotes],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WebPage]=S.[WebPage],[Zip]=S.[Zip]
WHEN NOT MATCHED THEN
	INSERT ([Active],[Address1],[Address2],[AddressLine3],[Attorney],[BankruptcyNoticeNumber],[BarDate],[CellPhone],[City],[ConfirmationDate],[ConversionDate],[CourtId],[CreatedById],[CreatedTime],[CustomerId],[DebtorinPossession],[DebtorNotes],[DischargeDate],[DismissalDate],[EMailId],[FaxNumber],[FilingDate],[FundsReceived_Amount],[FundsReceived_Currency],[LegalReliefRecordNumber],[LegalReliefType],[Neighborhood],[Notes],[OfficePhone],[PartyContactId],[PlacedwithOutsideCounsel],[POCDeadlineDate],[ReaffirmationDate],[ReceiverDirectPhone],[ReceiverEmailId],[ReceiverName],[ReceiverOfficePhone],[StateCourtDistrict],[StateId],[Status],[SubdivisionOrMunicipality],[TrusteeAppointed],[TrusteeName],[TrusteeNotes],[WebPage],[Zip])
    VALUES (S.[Active],S.[Address1],S.[Address2],S.[AddressLine3],S.[Attorney],S.[BankruptcyNoticeNumber],S.[BarDate],S.[CellPhone],S.[City],S.[ConfirmationDate],S.[ConversionDate],S.[CourtId],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[DebtorinPossession],S.[DebtorNotes],S.[DischargeDate],S.[DismissalDate],S.[EMailId],S.[FaxNumber],S.[FilingDate],S.[FundsReceived_Amount],S.[FundsReceived_Currency],S.[LegalReliefRecordNumber],S.[LegalReliefType],S.[Neighborhood],S.[Notes],S.[OfficePhone],S.[PartyContactId],S.[PlacedwithOutsideCounsel],S.[POCDeadlineDate],S.[ReaffirmationDate],S.[ReceiverDirectPhone],S.[ReceiverEmailId],S.[ReceiverName],S.[ReceiverOfficePhone],S.[StateCourtDistrict],S.[StateId],S.[Status],S.[SubdivisionOrMunicipality],S.[TrusteeAppointed],S.[TrusteeName],S.[TrusteeNotes],S.[WebPage],S.[Zip])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
