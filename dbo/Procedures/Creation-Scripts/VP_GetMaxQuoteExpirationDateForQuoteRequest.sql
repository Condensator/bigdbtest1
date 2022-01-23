SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[VP_GetMaxQuoteExpirationDateForQuoteRequest]
(
@PartyNumber NVARCHAR(MAX),
@MaxQuoteExpirationDays BIGINT OUT
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT
@MaxQuoteExpirationDays = V.MaxQuoteExpirationDays
FROM Vendors V
JOIN Parties P on V.Id = P.Id
WHERE V.Status='Active'
AND P.PartyNumber = @PartyNumber
SELECT @MaxQuoteExpirationDays
END

GO
