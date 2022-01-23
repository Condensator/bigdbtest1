SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePartyAddress]
(
 @val [dbo].[PartyAddress] READONLY
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
MERGE [dbo].[PartyAddresses] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AddressLine1]=S.[AddressLine1],[AddressLine2]=S.[AddressLine2],[AddressLine3]=S.[AddressLine3],[AttentionTo]=S.[AttentionTo],[City]=S.[City],[Description]=S.[Description],[Division]=S.[Division],[HomeAddressLine1]=S.[HomeAddressLine1],[HomeAddressLine2]=S.[HomeAddressLine2],[HomeAddressLine3]=S.[HomeAddressLine3],[HomeAttentionTo]=S.[HomeAttentionTo],[HomeCity]=S.[HomeCity],[HomeDivision]=S.[HomeDivision],[HomeNeighborhood]=S.[HomeNeighborhood],[HomePostalCode]=S.[HomePostalCode],[HomeSettlement]=S.[HomeSettlement],[HomeStateId]=S.[HomeStateId],[HomeSubdivisionOrMunicipality]=S.[HomeSubdivisionOrMunicipality],[IsActive]=S.[IsActive],[IsCompanyHeadquartersPermanentAddress]=S.[IsCompanyHeadquartersPermanentAddress],[IsCreateLocation]=S.[IsCreateLocation],[IsForDocumentation]=S.[IsForDocumentation],[IsHeadquarter]=S.[IsHeadquarter],[IsMain]=S.[IsMain],[Neighborhood]=S.[Neighborhood],[PostalCode]=S.[PostalCode],[Settlement]=S.[Settlement],[SFDCAddressId]=S.[SFDCAddressId],[StateId]=S.[StateId],[SubdivisionOrMunicipality]=S.[SubdivisionOrMunicipality],[TaxAreaId]=S.[TaxAreaId],[UniqueIdentifier]=S.[UniqueIdentifier],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VendorId]=S.[VendorId]
WHEN NOT MATCHED THEN
	INSERT ([AddressLine1],[AddressLine2],[AddressLine3],[AttentionTo],[City],[CreatedById],[CreatedTime],[Description],[Division],[HomeAddressLine1],[HomeAddressLine2],[HomeAddressLine3],[HomeAttentionTo],[HomeCity],[HomeDivision],[HomeNeighborhood],[HomePostalCode],[HomeSettlement],[HomeStateId],[HomeSubdivisionOrMunicipality],[IsActive],[IsCompanyHeadquartersPermanentAddress],[IsCreateLocation],[IsForDocumentation],[IsHeadquarter],[IsMain],[Neighborhood],[PartyId],[PostalCode],[Settlement],[SFDCAddressId],[StateId],[SubdivisionOrMunicipality],[TaxAreaId],[UniqueIdentifier],[VendorId])
    VALUES (S.[AddressLine1],S.[AddressLine2],S.[AddressLine3],S.[AttentionTo],S.[City],S.[CreatedById],S.[CreatedTime],S.[Description],S.[Division],S.[HomeAddressLine1],S.[HomeAddressLine2],S.[HomeAddressLine3],S.[HomeAttentionTo],S.[HomeCity],S.[HomeDivision],S.[HomeNeighborhood],S.[HomePostalCode],S.[HomeSettlement],S.[HomeStateId],S.[HomeSubdivisionOrMunicipality],S.[IsActive],S.[IsCompanyHeadquartersPermanentAddress],S.[IsCreateLocation],S.[IsForDocumentation],S.[IsHeadquarter],S.[IsMain],S.[Neighborhood],S.[PartyId],S.[PostalCode],S.[Settlement],S.[SFDCAddressId],S.[StateId],S.[SubdivisionOrMunicipality],S.[TaxAreaId],S.[UniqueIdentifier],S.[VendorId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
