SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePartyAddressDAMVRReportDetail]
(
 @val [dbo].[PartyAddressDAMVRReportDetail] READONLY
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
MERGE [dbo].[PartyAddressDAMVRReportDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Apartment]=S.[Apartment],[BuildingNumber]=S.[BuildingNumber],[DistrictName]=S.[DistrictName],[DistrictNameLatin]=S.[DistrictNameLatin],[Entrance]=S.[Entrance],[Floor]=S.[Floor],[LocationCode]=S.[LocationCode],[LocationName]=S.[LocationName],[LocationNameLatin]=S.[LocationNameLatin],[MunicipalityName]=S.[MunicipalityName],[MunicipalityNameLatin]=S.[MunicipalityNameLatin],[SettlementCode]=S.[SettlementCode],[SettlementName]=S.[SettlementName],[SettlementNameLatin]=S.[SettlementNameLatin],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Apartment],[BuildingNumber],[CreatedById],[CreatedTime],[DistrictName],[DistrictNameLatin],[Entrance],[Floor],[Id],[LocationCode],[LocationName],[LocationNameLatin],[MunicipalityName],[MunicipalityNameLatin],[SettlementCode],[SettlementName],[SettlementNameLatin])
    VALUES (S.[Apartment],S.[BuildingNumber],S.[CreatedById],S.[CreatedTime],S.[DistrictName],S.[DistrictNameLatin],S.[Entrance],S.[Floor],S.[Id],S.[LocationCode],S.[LocationName],S.[LocationNameLatin],S.[MunicipalityName],S.[MunicipalityNameLatin],S.[SettlementCode],S.[SettlementName],S.[SettlementNameLatin])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
