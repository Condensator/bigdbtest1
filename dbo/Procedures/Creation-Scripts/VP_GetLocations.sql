SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[VP_GetLocations]
(
@CustomerNumber NVARCHAR(MAX)
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT
Code,
Name,
AddressLine1,
AddressLine2,
l.Division,
l.City,
l.PostalCode,
l.Description,
s.ShortName as State,
s.Id as StateID,
c.LongName as Country,
c.ShortName as CountryShortName,
c.Id as CountryID,
j.Id as JurisdictionID
FROM Locations l
left join Customers Cust on l.CustomerId = Cust.Id
left join Parties P on Cust.Id = P.Id
join States s on l.StateId = s.Id
join Countries c on s.CountryId = c.Id
left join Jurisdictions j on l.JurisdictionId = j.Id
WHERE l.IsActive = 1
AND ((Cust.id is not null and P.PartyNumber = @CustomerNumber) OR (Cust.id is null))
END

GO
