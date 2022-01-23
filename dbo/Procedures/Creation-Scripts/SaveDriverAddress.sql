SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDriverAddress]
(
 @val [dbo].[DriverAddress] READONLY
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
MERGE [dbo].[DriverAddresses] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AddressLine1]=S.[AddressLine1],[AddressLine2]=S.[AddressLine2],[AddressLine3]=S.[AddressLine3],[AttentionTo]=S.[AttentionTo],[City]=S.[City],[Description]=S.[Description],[Division]=S.[Division],[HomeAddressLine1]=S.[HomeAddressLine1],[HomeAddressLine2]=S.[HomeAddressLine2],[HomeAddressLine3]=S.[HomeAddressLine3],[HomeCity]=S.[HomeCity],[HomeDivision]=S.[HomeDivision],[HomeNeighborhood]=S.[HomeNeighborhood],[HomePostalCode]=S.[HomePostalCode],[HomeStateId]=S.[HomeStateId],[HomeSubdivisionOrMunicipality]=S.[HomeSubdivisionOrMunicipality],[IsActive]=S.[IsActive],[IsForDocumentation]=S.[IsForDocumentation],[IsHeadquarter]=S.[IsHeadquarter],[IsImportedAddress]=S.[IsImportedAddress],[IsMain]=S.[IsMain],[Neighborhood]=S.[Neighborhood],[PartyAddressId]=S.[PartyAddressId],[PostalCode]=S.[PostalCode],[SFDCAddressId]=S.[SFDCAddressId],[StateId]=S.[StateId],[SubdivisionOrMunicipality]=S.[SubdivisionOrMunicipality],[UniqueIdentifier]=S.[UniqueIdentifier],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AddressLine1],[AddressLine2],[AddressLine3],[AttentionTo],[City],[CreatedById],[CreatedTime],[Description],[Division],[DriverId],[HomeAddressLine1],[HomeAddressLine2],[HomeAddressLine3],[HomeCity],[HomeDivision],[HomeNeighborhood],[HomePostalCode],[HomeStateId],[HomeSubdivisionOrMunicipality],[IsActive],[IsForDocumentation],[IsHeadquarter],[IsImportedAddress],[IsMain],[Neighborhood],[PartyAddressId],[PostalCode],[SFDCAddressId],[StateId],[SubdivisionOrMunicipality],[UniqueIdentifier])
    VALUES (S.[AddressLine1],S.[AddressLine2],S.[AddressLine3],S.[AttentionTo],S.[City],S.[CreatedById],S.[CreatedTime],S.[Description],S.[Division],S.[DriverId],S.[HomeAddressLine1],S.[HomeAddressLine2],S.[HomeAddressLine3],S.[HomeCity],S.[HomeDivision],S.[HomeNeighborhood],S.[HomePostalCode],S.[HomeStateId],S.[HomeSubdivisionOrMunicipality],S.[IsActive],S.[IsForDocumentation],S.[IsHeadquarter],S.[IsImportedAddress],S.[IsMain],S.[Neighborhood],S.[PartyAddressId],S.[PostalCode],S.[SFDCAddressId],S.[StateId],S.[SubdivisionOrMunicipality],S.[UniqueIdentifier])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
