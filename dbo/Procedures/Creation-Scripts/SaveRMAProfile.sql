SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveRMAProfile]
(
 @val [dbo].[RMAProfile] READONLY
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
MERGE [dbo].[RMAProfiles] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActualPickupDate]=S.[ActualPickupDate],[AuditReceivedDate]=S.[AuditReceivedDate],[AuditRequired]=S.[AuditRequired],[AuthorizedById]=S.[AuthorizedById],[Bandling]=S.[Bandling],[CallFirst]=S.[CallFirst],[Canadian]=S.[Canadian],[CertificateofInsuranceRequired]=S.[CertificateofInsuranceRequired],[CityTruckRequired]=S.[CityTruckRequired],[ClimateControl]=S.[ClimateControl],[CurrencyId]=S.[CurrencyId],[CustomerId]=S.[CustomerId],[DeInstallationRequired]=S.[DeInstallationRequired],[DeliveryDate]=S.[DeliveryDate],[DockHeight]=S.[DockHeight],[DockHours]=S.[DockHours],[EquipmentDispositionComment]=S.[EquipmentDispositionComment],[EstimatedDimensions]=S.[EstimatedDimensions],[EstimatedPickupDate]=S.[EstimatedPickupDate],[EstimatedWeight]=S.[EstimatedWeight],[ExpectedDeliveryDate]=S.[ExpectedDeliveryDate],[FloorCoveringNeeded]=S.[FloorCoveringNeeded],[FreightComment]=S.[FreightComment],[InsuranceAmount_Amount]=S.[InsuranceAmount_Amount],[InsuranceAmount_Currency]=S.[InsuranceAmount_Currency],[InsuredValue_Amount]=S.[InsuredValue_Amount],[InsuredValue_Currency]=S.[InsuredValue_Currency],[LastDateToBill]=S.[LastDateToBill],[Licenses]=S.[Licenses],[NotifiedCustomer]=S.[NotifiedCustomer],[NotifiedRefurbishmentCenter]=S.[NotifiedRefurbishmentCenter],[NotifiedShippingCompany]=S.[NotifiedShippingCompany],[PackingNeeded]=S.[PackingNeeded],[Palletized]=S.[Palletized],[PasswordsRequired]=S.[PasswordsRequired],[ProductManagerId]=S.[ProductManagerId],[RestoreSoftware]=S.[RestoreSoftware],[RMAStatus]=S.[RMAStatus],[SalesRepId]=S.[SalesRepId],[ShipFromAdditionalContact]=S.[ShipFromAdditionalContact],[ShipFromAddressLine1]=S.[ShipFromAddressLine1],[ShipFromAddressLine2]=S.[ShipFromAddressLine2],[ShipFromCity]=S.[ShipFromCity],[ShipFromEMailId1]=S.[ShipFromEMailId1],[ShipFromEMailId2]=S.[ShipFromEMailId2],[ShipFromInside]=S.[ShipFromInside],[ShipFromLiftgate]=S.[ShipFromLiftgate],[ShipFromLocationId]=S.[ShipFromLocationId],[ShipFromMobilePhoneNumber1]=S.[ShipFromMobilePhoneNumber1],[ShipFromMobilePhoneNumber2]=S.[ShipFromMobilePhoneNumber2],[ShipFromPhoneNumber1]=S.[ShipFromPhoneNumber1],[ShipFromPhoneNumber2]=S.[ShipFromPhoneNumber2],[ShipFromPrimaryContact]=S.[ShipFromPrimaryContact],[ShipFromStateId]=S.[ShipFromStateId],[ShipFromZip]=S.[ShipFromZip],[ShippingCompanyId]=S.[ShippingCompanyId],[ShippingOption]=S.[ShippingOption],[ShipToEMailId1]=S.[ShipToEMailId1],[ShipToEMailId2]=S.[ShipToEMailId2],[ShipToId]=S.[ShipToId],[ShipToInside]=S.[ShipToInside],[ShipToLiftgate]=S.[ShipToLiftgate],[ShipToLocationId]=S.[ShipToLocationId],[ShipToMobilePhoneNumber1]=S.[ShipToMobilePhoneNumber1],[ShipToMobilePhoneNumber2]=S.[ShipToMobilePhoneNumber2],[ShipToPhoneNumber1]=S.[ShipToPhoneNumber1],[ShipToPhoneNumber2]=S.[ShipToPhoneNumber2],[TrackingNumber]=S.[TrackingNumber],[TransactionNumber]=S.[TransactionNumber],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Wheels]=S.[Wheels],[WipeHardDrives]=S.[WipeHardDrives]
WHEN NOT MATCHED THEN
	INSERT ([ActualPickupDate],[AuditReceivedDate],[AuditRequired],[AuthorizedById],[Bandling],[CallFirst],[Canadian],[CertificateofInsuranceRequired],[CityTruckRequired],[ClimateControl],[CreatedById],[CreatedTime],[CurrencyId],[CustomerId],[DeInstallationRequired],[DeliveryDate],[DockHeight],[DockHours],[EquipmentDispositionComment],[EstimatedDimensions],[EstimatedPickupDate],[EstimatedWeight],[ExpectedDeliveryDate],[FloorCoveringNeeded],[FreightComment],[InsuranceAmount_Amount],[InsuranceAmount_Currency],[InsuredValue_Amount],[InsuredValue_Currency],[LastDateToBill],[Licenses],[NotifiedCustomer],[NotifiedRefurbishmentCenter],[NotifiedShippingCompany],[PackingNeeded],[Palletized],[PasswordsRequired],[ProductManagerId],[RestoreSoftware],[RMAStatus],[SalesRepId],[ShipFromAdditionalContact],[ShipFromAddressLine1],[ShipFromAddressLine2],[ShipFromCity],[ShipFromEMailId1],[ShipFromEMailId2],[ShipFromInside],[ShipFromLiftgate],[ShipFromLocationId],[ShipFromMobilePhoneNumber1],[ShipFromMobilePhoneNumber2],[ShipFromPhoneNumber1],[ShipFromPhoneNumber2],[ShipFromPrimaryContact],[ShipFromStateId],[ShipFromZip],[ShippingCompanyId],[ShippingOption],[ShipToEMailId1],[ShipToEMailId2],[ShipToId],[ShipToInside],[ShipToLiftgate],[ShipToLocationId],[ShipToMobilePhoneNumber1],[ShipToMobilePhoneNumber2],[ShipToPhoneNumber1],[ShipToPhoneNumber2],[TrackingNumber],[TransactionNumber],[Wheels],[WipeHardDrives])
    VALUES (S.[ActualPickupDate],S.[AuditReceivedDate],S.[AuditRequired],S.[AuthorizedById],S.[Bandling],S.[CallFirst],S.[Canadian],S.[CertificateofInsuranceRequired],S.[CityTruckRequired],S.[ClimateControl],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[CustomerId],S.[DeInstallationRequired],S.[DeliveryDate],S.[DockHeight],S.[DockHours],S.[EquipmentDispositionComment],S.[EstimatedDimensions],S.[EstimatedPickupDate],S.[EstimatedWeight],S.[ExpectedDeliveryDate],S.[FloorCoveringNeeded],S.[FreightComment],S.[InsuranceAmount_Amount],S.[InsuranceAmount_Currency],S.[InsuredValue_Amount],S.[InsuredValue_Currency],S.[LastDateToBill],S.[Licenses],S.[NotifiedCustomer],S.[NotifiedRefurbishmentCenter],S.[NotifiedShippingCompany],S.[PackingNeeded],S.[Palletized],S.[PasswordsRequired],S.[ProductManagerId],S.[RestoreSoftware],S.[RMAStatus],S.[SalesRepId],S.[ShipFromAdditionalContact],S.[ShipFromAddressLine1],S.[ShipFromAddressLine2],S.[ShipFromCity],S.[ShipFromEMailId1],S.[ShipFromEMailId2],S.[ShipFromInside],S.[ShipFromLiftgate],S.[ShipFromLocationId],S.[ShipFromMobilePhoneNumber1],S.[ShipFromMobilePhoneNumber2],S.[ShipFromPhoneNumber1],S.[ShipFromPhoneNumber2],S.[ShipFromPrimaryContact],S.[ShipFromStateId],S.[ShipFromZip],S.[ShippingCompanyId],S.[ShippingOption],S.[ShipToEMailId1],S.[ShipToEMailId2],S.[ShipToId],S.[ShipToInside],S.[ShipToLiftgate],S.[ShipToLocationId],S.[ShipToMobilePhoneNumber1],S.[ShipToMobilePhoneNumber2],S.[ShipToPhoneNumber1],S.[ShipToPhoneNumber2],S.[TrackingNumber],S.[TransactionNumber],S.[Wheels],S.[WipeHardDrives])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
