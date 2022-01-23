SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[VP_CreateVendorSalesRepContactDetail]
(
@VendorNumber NVARCHAR(40),
@VendorContactTypeName NVARCHAR(100),
@VendorContactFirstName NVARCHAR(20),
@VendorContactLastName NVARCHAR(20),
@CreditApplicationUniqueIdentifier NVARCHAR(40),
@CreatedTime DATETIMEOFFSET = NULL
)
AS
DECLARE @VendorId BIGINT = 0
DECLARE @VendorContactId BIGINT = 0
DECLARE @VendorContactTypeId BIGINT = 0
DECLARE @VendorContactCount BIGINT =1
DECLARE @CreatedBy BIGINT = 0
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
IF(@CreatedTime IS NULL)
SET @CreatedTime = SYSDATETIMEOFFSET();
SELECT @VendorId = Id FROM Parties
WHERE PartyNumber = @VendorNumber
SELECT @VendorContactId = Id FROM PartyContacts
WHERE FirstName = @VendorContactFirstName
AND LastName = @VendorContactLastName
AND PartyId = @VendorId
SELECT @CreatedBy = Id From Users
WHERE LoginName = 'System.User'
IF(@VendorContactId > 0)
BEGIN
UPDATE PartyContacts SET IsActive = 1 WHERE Id = @VendorContactId
SELECT @VendorContactTypeId = Id FROM PartyContactTypes
WHERE ContactType = @VendorContactTypeName
AND PartyContactId = @VendorContactId
IF(@VendorContactTypeId > 0)
UPDATE PartyContactTypes SET IsActive = 1 WHERE Id = @VendorContactTypeId
ELSE
INSERT INTO PartyContactTypes (ContactType,IsActive,PartyContactId,CreatedById,CreatedTime) VALUES
(@VendorContactTypeName,1,@VendorContactId,@CreatedBy,@CreatedTime)
END
ELSE
BEGIN
SELECT @VendorContactCount = COUNT(ID) from PartyContacts WHERE PartyId = @VendorId
INSERT INTO PartyContacts (FirstName,LastName,IsActive,UniqueIdentifier,PartyId,IsSCRA,CreatedById,CreatedTime,
OwnershipPercentage,MortgageHighCredit_Amount,MortgageHighCredit_Currency,CIPDocumentSourceForTaxIdOrSSN,
CIPDocumentSourceForAddress,CIPDocumentSourceForName,FullName,IsAssumptionApproved,IsFromAssumption,
IsBookingNotificationAllowed,IsCreditNotificationAllowed,BusinessStartTimeInHours, BusinessStartTimeInMinutes, BusinessEndTimeInHours, BusinessEndTimeInMinutes)
VALUES
(@VendorContactFirstName,@VendorContactLastName,1,@VendorNumber+'-'+ CAST((@VendorContactCount + 1) AS NVARCHAR(10)),
@VendorId,0,@CreatedBy,@CreatedTime,0.00,0.00,'USD','_','_','_',@VendorContactFirstName +' ' +@VendorContactLastName,
CONVERT(BIT,0),CONVERT(BIT,0),CONVERT(BIT,0),CONVERT(BIT,0),0,0,0,0)
SET @VendorContactId = (SELECT SCOPE_IDENTITY())
INSERT INTO PartyContactTypes (ContactType,IsActive,PartyContactId,CreatedById,CreatedTime,IsForDocumentation) VALUES
(@VendorContactTypeName,1,@VendorContactId,@CreatedBy,@CreatedTime,CONVERT(BIT,0))
END
UPDATE CreditApplications SET VendorContactId = @VendorContactId
WHERE CreditApplications.Id IN (SELECT Id FROM Opportunities WHERE
Number = @CreditApplicationUniqueIdentifier )
END

GO
