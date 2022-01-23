SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePlate]
(
 @val [dbo].[Plate] READONLY
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
MERGE [dbo].[Plates] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActivationDate]=S.[ActivationDate],[AssetId]=S.[AssetId],[AssignmentDate]=S.[AssignmentDate],[DeactivationDate]=S.[DeactivationDate],[DeactivationReason]=S.[DeactivationReason],[DMVAddressLine1]=S.[DMVAddressLine1],[DMVAddressLine2]=S.[DMVAddressLine2],[DMVAddressLine3]=S.[DMVAddressLine3],[DMVAddressType]=S.[DMVAddressType],[DMVAttentionTo]=S.[DMVAttentionTo],[DMVCity]=S.[DMVCity],[DMVCountryId]=S.[DMVCountryId],[DMVDivision]=S.[DMVDivision],[DMVNeighborhood]=S.[DMVNeighborhood],[DMVPostalCode]=S.[DMVPostalCode],[DMVStateId]=S.[DMVStateId],[DMVSubdivisionOrMunicipality]=S.[DMVSubdivisionOrMunicipality],[DoNotRenewRegistration]=S.[DoNotRenewRegistration],[ExpiryDate]=S.[ExpiryDate],[IsActive]=S.[IsActive],[IssuedDate]=S.[IssuedDate],[PlateNumber]=S.[PlateNumber],[PlateTypeId]=S.[PlateTypeId],[PlateUniqueNumber]=S.[PlateUniqueNumber],[RegistantAttentionTo]=S.[RegistantAttentionTo],[RegistantStateId]=S.[RegistantStateId],[RegistrantAddressLine1]=S.[RegistrantAddressLine1],[RegistrantAddressLine2]=S.[RegistrantAddressLine2],[RegistrantAddressLine3]=S.[RegistrantAddressLine3],[RegistrantCity]=S.[RegistrantCity],[RegistrantCountryId]=S.[RegistrantCountryId],[RegistrantDivision]=S.[RegistrantDivision],[RegistrantNeighborhood]=S.[RegistrantNeighborhood],[RegistrantPostalCode]=S.[RegistrantPostalCode],[RegistrantSubdivisionOrMunicipality]=S.[RegistrantSubdivisionOrMunicipality],[RegistrationAddressType]=S.[RegistrationAddressType],[RegistrationCountryId]=S.[RegistrationCountryId],[RegistrationName]=S.[RegistrationName],[RegistrationStateId]=S.[RegistrationStateId],[ResponsibleEntity]=S.[ResponsibleEntity],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ActivationDate],[AssetId],[AssignmentDate],[CreatedById],[CreatedTime],[DeactivationDate],[DeactivationReason],[DMVAddressLine1],[DMVAddressLine2],[DMVAddressLine3],[DMVAddressType],[DMVAttentionTo],[DMVCity],[DMVCountryId],[DMVDivision],[DMVNeighborhood],[DMVPostalCode],[DMVStateId],[DMVSubdivisionOrMunicipality],[DoNotRenewRegistration],[ExpiryDate],[IsActive],[IssuedDate],[PlateNumber],[PlateTypeId],[PlateUniqueNumber],[RegistantAttentionTo],[RegistantStateId],[RegistrantAddressLine1],[RegistrantAddressLine2],[RegistrantAddressLine3],[RegistrantCity],[RegistrantCountryId],[RegistrantDivision],[RegistrantNeighborhood],[RegistrantPostalCode],[RegistrantSubdivisionOrMunicipality],[RegistrationAddressType],[RegistrationCountryId],[RegistrationName],[RegistrationStateId],[ResponsibleEntity])
    VALUES (S.[ActivationDate],S.[AssetId],S.[AssignmentDate],S.[CreatedById],S.[CreatedTime],S.[DeactivationDate],S.[DeactivationReason],S.[DMVAddressLine1],S.[DMVAddressLine2],S.[DMVAddressLine3],S.[DMVAddressType],S.[DMVAttentionTo],S.[DMVCity],S.[DMVCountryId],S.[DMVDivision],S.[DMVNeighborhood],S.[DMVPostalCode],S.[DMVStateId],S.[DMVSubdivisionOrMunicipality],S.[DoNotRenewRegistration],S.[ExpiryDate],S.[IsActive],S.[IssuedDate],S.[PlateNumber],S.[PlateTypeId],S.[PlateUniqueNumber],S.[RegistantAttentionTo],S.[RegistantStateId],S.[RegistrantAddressLine1],S.[RegistrantAddressLine2],S.[RegistrantAddressLine3],S.[RegistrantCity],S.[RegistrantCountryId],S.[RegistrantDivision],S.[RegistrantNeighborhood],S.[RegistrantPostalCode],S.[RegistrantSubdivisionOrMunicipality],S.[RegistrationAddressType],S.[RegistrationCountryId],S.[RegistrationName],S.[RegistrationStateId],S.[ResponsibleEntity])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
