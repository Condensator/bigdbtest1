SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetLegalReliefDetailsForCustomerService]
(
@CustomerNumber nvarchar(50)
)
AS
BEGIN
DECLARE @CustomerId BigInt
SET @CustomerId = (Select Id from Parties where PartyNumber = @CustomerNumber)
SELECT
LegalReliefRecordNumber
,LegalReliefs.FilingDate
,LegalReliefs.POCDeadlineDate
,LegalReliefs.ReaffirmationDate
,LegalReliefs.BankruptcyNoticeNumber
,LegalReliefs.Status
,LegalReliefs.StateCourtDistrict
,LegalReliefs.DischargeDate
,LegalReliefs.BarDate
,LegalReliefs.DismissalDate
,LegalReliefs.ReceiverOfficePhone
,LegalReliefs.ReceiverDirectPhone
,LegalReliefs.ReceiverEmailId
,LegalReliefBankruptcyChapters.Chapter BankruptcyChapter
,Parties.PartyNumber CustomerNumber
,Parties.PartyName CustomerName
,LegalReliefs.Id [LegalReliefId]
,LegalReliefs.Active
FROM LegalReliefs
INNER JOIN Parties ON LegalReliefs.CustomerId = Parties.Id
LEFT JOIN LegalReliefBankruptcyChapters ON LegalReliefs.Id = LegalReliefId
WHERE CustomerId = @CustomerId
AND LegalReliefBankruptcyChapters.Active = 1
END

GO
