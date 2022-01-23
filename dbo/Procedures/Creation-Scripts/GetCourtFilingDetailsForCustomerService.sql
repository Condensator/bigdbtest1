SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetCourtFilingDetailsForCustomerService]
(
@CustomerNumber nvarchar(50),
@CurrentPortfolioId BigInt
)
AS
BEGIN
DECLARE @CustomerId BigInt
SET @CustomerId = (Select Id from Parties where PartyNumber = @CustomerNumber)
SELECT
[RecordStartDate]
,[CaseNumber]
,[FilingDate]
,[LegalRelief]
,[RecordStatus]
,Parties.PartyNumber [CustomerNumber]
,Parties.PartyName [CustomerName]
,Users.FullName [UserName]
,CourtFilings.[Id] CourtFilingId
,CourtFilings.IsActive [Active]
FROM CourtFilings
INNER JOIN Users ON Users.Id = CourtFilings.CreatedById
INNER JOIN Parties ON Parties.Id = CourtFilings.CustomerId
WHERE CustomerId = @CustomerId and Parties.PortfolioId=@CurrentPortfolioId
ORDER BY [RecordStartDate] DESC
END

GO
