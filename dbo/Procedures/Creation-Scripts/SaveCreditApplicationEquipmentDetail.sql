SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCreditApplicationEquipmentDetail]
(
 @val [dbo].[CreditApplicationEquipmentDetail] READONLY
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
MERGE [dbo].[CreditApplicationEquipmentDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AgeofAsset]=S.[AgeofAsset],[AssetClassConfigId]=S.[AssetClassConfigId],[AssetTypeId]=S.[AssetTypeId],[Cost_Amount]=S.[Cost_Amount],[Cost_Currency]=S.[Cost_Currency],[DateOfProduction]=S.[DateOfProduction],[EngineCapacity]=S.[EngineCapacity],[EquipmentDescription]=S.[EquipmentDescription],[EquipmentVendorId]=S.[EquipmentVendorId],[InsuranceAssessment_Amount]=S.[InsuranceAssessment_Amount],[InsuranceAssessment_Currency]=S.[InsuranceAssessment_Currency],[IsActive]=S.[IsActive],[IsFromQuote]=S.[IsFromQuote],[IsImported]=S.[IsImported],[IsNewLocation]=S.[IsNewLocation],[IsVAT]=S.[IsVAT],[KW]=S.[KW],[LoadCapacity]=S.[LoadCapacity],[LocationId]=S.[LocationId],[MakeId]=S.[MakeId],[ModelId]=S.[ModelId],[ModelYear]=S.[ModelYear],[Number]=S.[Number],[PricingGroupId]=S.[PricingGroupId],[ProgramAssetTypeId]=S.[ProgramAssetTypeId],[Quantity]=S.[Quantity],[Seats]=S.[Seats],[TaxCodeId]=S.[TaxCodeId],[TechnicallyPermissibleMass]=S.[TechnicallyPermissibleMass],[TotalCost_Amount]=S.[TotalCost_Amount],[TotalCost_Currency]=S.[TotalCost_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UsageCondition]=S.[UsageCondition],[ValueInclVAT_Amount]=S.[ValueInclVAT_Amount],[ValueInclVAT_Currency]=S.[ValueInclVAT_Currency],[VATAmount_Amount]=S.[VATAmount_Amount],[VATAmount_Currency]=S.[VATAmount_Currency]
WHEN NOT MATCHED THEN
	INSERT ([AgeofAsset],[AssetClassConfigId],[AssetTypeId],[Cost_Amount],[Cost_Currency],[CreatedById],[CreatedTime],[CreditApplicationId],[DateOfProduction],[EngineCapacity],[EquipmentDescription],[EquipmentVendorId],[InsuranceAssessment_Amount],[InsuranceAssessment_Currency],[IsActive],[IsFromQuote],[IsImported],[IsNewLocation],[IsVAT],[KW],[LoadCapacity],[LocationId],[MakeId],[ModelId],[ModelYear],[Number],[PricingGroupId],[ProgramAssetTypeId],[Quantity],[Seats],[TaxCodeId],[TechnicallyPermissibleMass],[TotalCost_Amount],[TotalCost_Currency],[UsageCondition],[ValueInclVAT_Amount],[ValueInclVAT_Currency],[VATAmount_Amount],[VATAmount_Currency])
    VALUES (S.[AgeofAsset],S.[AssetClassConfigId],S.[AssetTypeId],S.[Cost_Amount],S.[Cost_Currency],S.[CreatedById],S.[CreatedTime],S.[CreditApplicationId],S.[DateOfProduction],S.[EngineCapacity],S.[EquipmentDescription],S.[EquipmentVendorId],S.[InsuranceAssessment_Amount],S.[InsuranceAssessment_Currency],S.[IsActive],S.[IsFromQuote],S.[IsImported],S.[IsNewLocation],S.[IsVAT],S.[KW],S.[LoadCapacity],S.[LocationId],S.[MakeId],S.[ModelId],S.[ModelYear],S.[Number],S.[PricingGroupId],S.[ProgramAssetTypeId],S.[Quantity],S.[Seats],S.[TaxCodeId],S.[TechnicallyPermissibleMass],S.[TotalCost_Amount],S.[TotalCost_Currency],S.[UsageCondition],S.[ValueInclVAT_Amount],S.[ValueInclVAT_Currency],S.[VATAmount_Amount],S.[VATAmount_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
