SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCollateralTracking]
(
 @val [dbo].[CollateralTracking] READONLY
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
MERGE [dbo].[CollateralTrackings] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[AssignedTo]=S.[AssignedTo],[CollateralPosition]=S.[CollateralPosition],[CollateralStatus]=S.[CollateralStatus],[CollateralTitleReleaseStatus]=S.[CollateralTitleReleaseStatus],[CollateralType]=S.[CollateralType],[CompletingTitleWork]=S.[CompletingTitleWork],[ContactName]=S.[ContactName],[ContactPhone]=S.[ContactPhone],[EntityId]=S.[EntityId],[EntityType]=S.[EntityType],[FAAFilingNumber]=S.[FAAFilingNumber],[InternationalRegistryFileNumber]=S.[InternationalRegistryFileNumber],[IsActive]=S.[IsActive],[IsCollateralConfirmation]=S.[IsCollateralConfirmation],[IsCrossCollateralized]=S.[IsCrossCollateralized],[PlateTailNumberVessel]=S.[PlateTailNumberVessel],[RegistrationRenewalDate]=S.[RegistrationRenewalDate],[ReleasedTo]=S.[ReleasedTo],[ThirdPartyTitleAgency]=S.[ThirdPartyTitleAgency],[Title]=S.[Title],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[AssignedTo],[CollateralPosition],[CollateralStatus],[CollateralTitleReleaseStatus],[CollateralType],[CompletingTitleWork],[ContactName],[ContactPhone],[CreatedById],[CreatedTime],[EntityId],[EntityType],[FAAFilingNumber],[InternationalRegistryFileNumber],[IsActive],[IsCollateralConfirmation],[IsCrossCollateralized],[PlateTailNumberVessel],[RegistrationRenewalDate],[ReleasedTo],[ThirdPartyTitleAgency],[Title])
    VALUES (S.[AssetId],S.[AssignedTo],S.[CollateralPosition],S.[CollateralStatus],S.[CollateralTitleReleaseStatus],S.[CollateralType],S.[CompletingTitleWork],S.[ContactName],S.[ContactPhone],S.[CreatedById],S.[CreatedTime],S.[EntityId],S.[EntityType],S.[FAAFilingNumber],S.[InternationalRegistryFileNumber],S.[IsActive],S.[IsCollateralConfirmation],S.[IsCrossCollateralized],S.[PlateTailNumberVessel],S.[RegistrationRenewalDate],S.[ReleasedTo],S.[ThirdPartyTitleAgency],S.[Title])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
