SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCreditProfileEquipmentDetail]
(
 @val [dbo].[CreditProfileEquipmentDetail] READONLY
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
MERGE [dbo].[CreditProfileEquipmentDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetTypeId]=S.[AssetTypeId],[Cost_Amount]=S.[Cost_Amount],[Cost_Currency]=S.[Cost_Currency],[CustomerExpectedResidual_Amount]=S.[CustomerExpectedResidual_Amount],[CustomerExpectedResidual_Currency]=S.[CustomerExpectedResidual_Currency],[CustomerExpectedResidualFactor]=S.[CustomerExpectedResidualFactor],[Description]=S.[Description],[EquipmentVendorId]=S.[EquipmentVendorId],[GuaranteedResidual_Amount]=S.[GuaranteedResidual_Amount],[GuaranteedResidual_Currency]=S.[GuaranteedResidual_Currency],[GuaranteedResidualFactor]=S.[GuaranteedResidualFactor],[InterestRate]=S.[InterestRate],[InterimRent_Amount]=S.[InterimRent_Amount],[InterimRent_Currency]=S.[InterimRent_Currency],[InterimRentFactor]=S.[InterimRentFactor],[IsActive]=S.[IsActive],[IsFromQuote]=S.[IsFromQuote],[IsNewLocation]=S.[IsNewLocation],[LocationId]=S.[LocationId],[ModelYear]=S.[ModelYear],[Number]=S.[Number],[PricingGroupId]=S.[PricingGroupId],[ProgramAssetTypeId]=S.[ProgramAssetTypeId],[Quantity]=S.[Quantity],[Rent_Amount]=S.[Rent_Amount],[Rent_Currency]=S.[Rent_Currency],[RentFactor]=S.[RentFactor],[TaxCodeId]=S.[TaxCodeId],[TotalCost_Amount]=S.[TotalCost_Amount],[TotalCost_Currency]=S.[TotalCost_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UsageCondition]=S.[UsageCondition],[VATAmount_Amount]=S.[VATAmount_Amount],[VATAmount_Currency]=S.[VATAmount_Currency]
WHEN NOT MATCHED THEN
	INSERT ([AssetTypeId],[Cost_Amount],[Cost_Currency],[CreatedById],[CreatedTime],[CreditApprovedStructureId],[CustomerExpectedResidual_Amount],[CustomerExpectedResidual_Currency],[CustomerExpectedResidualFactor],[Description],[EquipmentVendorId],[GuaranteedResidual_Amount],[GuaranteedResidual_Currency],[GuaranteedResidualFactor],[InterestRate],[InterimRent_Amount],[InterimRent_Currency],[InterimRentFactor],[IsActive],[IsFromQuote],[IsNewLocation],[LocationId],[ModelYear],[Number],[PricingGroupId],[ProgramAssetTypeId],[Quantity],[Rent_Amount],[Rent_Currency],[RentFactor],[TaxCodeId],[TotalCost_Amount],[TotalCost_Currency],[UsageCondition],[VATAmount_Amount],[VATAmount_Currency])
    VALUES (S.[AssetTypeId],S.[Cost_Amount],S.[Cost_Currency],S.[CreatedById],S.[CreatedTime],S.[CreditApprovedStructureId],S.[CustomerExpectedResidual_Amount],S.[CustomerExpectedResidual_Currency],S.[CustomerExpectedResidualFactor],S.[Description],S.[EquipmentVendorId],S.[GuaranteedResidual_Amount],S.[GuaranteedResidual_Currency],S.[GuaranteedResidualFactor],S.[InterestRate],S.[InterimRent_Amount],S.[InterimRent_Currency],S.[InterimRentFactor],S.[IsActive],S.[IsFromQuote],S.[IsNewLocation],S.[LocationId],S.[ModelYear],S.[Number],S.[PricingGroupId],S.[ProgramAssetTypeId],S.[Quantity],S.[Rent_Amount],S.[Rent_Currency],S.[RentFactor],S.[TaxCodeId],S.[TotalCost_Amount],S.[TotalCost_Currency],S.[UsageCondition],S.[VATAmount_Amount],S.[VATAmount_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
