SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveUser]
(
 @val [dbo].[User] READONLY
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
MERGE [dbo].[Users] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActivationDate]=S.[ActivationDate],[AdminUserId]=S.[AdminUserId],[ApprovalStatus]=S.[ApprovalStatus],[BillToId]=S.[BillToId],[CanLogin]=S.[CanLogin],[ContractId]=S.[ContractId],[CreationDate]=S.[CreationDate],[DeactivationDate]=S.[DeactivationDate],[DefaultBusinessUnitId]=S.[DefaultBusinessUnitId],[DiligenzAccountID]=S.[DiligenzAccountID],[DiligenzContactNumber]=S.[DiligenzContactNumber],[DomainId]=S.[DomainId],[EGN_CT]=S.[EGN_CT],[Email]=S.[Email],[ESignJWTUserId]=S.[ESignJWTUserId],[ExternalUserId]=S.[ExternalUserId],[FaxNumber]=S.[FaxNumber],[FirstName]=S.[FirstName],[ForcePasswordReset]=S.[ForcePasswordReset],[FullName]=S.[FullName],[IdCardNumber]=S.[IdCardNumber],[IsAdminBlocked]=S.[IsAdminBlocked],[IsAttorney]=S.[IsAttorney],[IsEmailNotificationAllowed]=S.[IsEmailNotificationAllowed],[IsFactorAuthenticationEnabled]=S.[IsFactorAuthenticationEnabled],[IsFactorAuthorizationEnabled]=S.[IsFactorAuthorizationEnabled],[IsFullAccess]=S.[IsFullAccess],[IsLoginBlocked]=S.[IsLoginBlocked],[IssuedBy]=S.[IssuedBy],[IssuedIn]=S.[IssuedIn],[IsWindowsAuthenticated]=S.[IsWindowsAuthenticated],[LastName]=S.[LastName],[LoginBlockedTime]=S.[LoginBlockedTime],[LoginEffectiveDate]=S.[LoginEffectiveDate],[LoginExpiryDate]=S.[LoginExpiryDate],[LoginFailureCounter]=S.[LoginFailureCounter],[LoginName]=S.[LoginName],[MiddleName]=S.[MiddleName],[MultiFactorAuthenticationId]=S.[MultiFactorAuthenticationId],[Notary]=S.[Notary],[NotaryRegistrationNumber]=S.[NotaryRegistrationNumber],[OrganizationConfigId]=S.[OrganizationConfigId],[Password]=S.[Password],[PermanentAddressCity]=S.[PermanentAddressCity],[PhoneExtensionNumber]=S.[PhoneExtensionNumber],[PhoneNumber]=S.[PhoneNumber],[PowerOfAttorneyNumber]=S.[PowerOfAttorneyNumber],[ProfilePicture_Content]=S.[ProfilePicture_Content],[ProfilePicture_Source]=S.[ProfilePicture_Source],[ProfilePicture_Type]=S.[ProfilePicture_Type],[Role]=S.[Role],[SignatureNumber]=S.[SignatureNumber],[Title]=S.[Title],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Validity]=S.[Validity]
WHEN NOT MATCHED THEN
	INSERT ([ActivationDate],[AdminUserId],[ApprovalStatus],[BillToId],[CanLogin],[ContractId],[CreatedById],[CreatedTime],[CreationDate],[DeactivationDate],[DefaultBusinessUnitId],[DiligenzAccountID],[DiligenzContactNumber],[DomainId],[EGN_CT],[Email],[ESignJWTUserId],[ExternalUserId],[FaxNumber],[FirstName],[ForcePasswordReset],[FullName],[IdCardNumber],[IsAdminBlocked],[IsAttorney],[IsEmailNotificationAllowed],[IsFactorAuthenticationEnabled],[IsFactorAuthorizationEnabled],[IsFullAccess],[IsLoginBlocked],[IssuedBy],[IssuedIn],[IsWindowsAuthenticated],[LastName],[LoginBlockedTime],[LoginEffectiveDate],[LoginExpiryDate],[LoginFailureCounter],[LoginName],[MiddleName],[MultiFactorAuthenticationId],[Notary],[NotaryRegistrationNumber],[OrganizationConfigId],[Password],[PermanentAddressCity],[PhoneExtensionNumber],[PhoneNumber],[PowerOfAttorneyNumber],[ProfilePicture_Content],[ProfilePicture_Source],[ProfilePicture_Type],[Role],[SignatureNumber],[Title],[Validity])
    VALUES (S.[ActivationDate],S.[AdminUserId],S.[ApprovalStatus],S.[BillToId],S.[CanLogin],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[CreationDate],S.[DeactivationDate],S.[DefaultBusinessUnitId],S.[DiligenzAccountID],S.[DiligenzContactNumber],S.[DomainId],S.[EGN_CT],S.[Email],S.[ESignJWTUserId],S.[ExternalUserId],S.[FaxNumber],S.[FirstName],S.[ForcePasswordReset],S.[FullName],S.[IdCardNumber],S.[IsAdminBlocked],S.[IsAttorney],S.[IsEmailNotificationAllowed],S.[IsFactorAuthenticationEnabled],S.[IsFactorAuthorizationEnabled],S.[IsFullAccess],S.[IsLoginBlocked],S.[IssuedBy],S.[IssuedIn],S.[IsWindowsAuthenticated],S.[LastName],S.[LoginBlockedTime],S.[LoginEffectiveDate],S.[LoginExpiryDate],S.[LoginFailureCounter],S.[LoginName],S.[MiddleName],S.[MultiFactorAuthenticationId],S.[Notary],S.[NotaryRegistrationNumber],S.[OrganizationConfigId],S.[Password],S.[PermanentAddressCity],S.[PhoneExtensionNumber],S.[PhoneNumber],S.[PowerOfAttorneyNumber],S.[ProfilePicture_Content],S.[ProfilePicture_Source],S.[ProfilePicture_Type],S.[Role],S.[SignatureNumber],S.[Title],S.[Validity])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
