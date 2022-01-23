SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveProposalEquipmentDetail]
(
 @val [dbo].[ProposalEquipmentDetail] READONLY
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
MERGE [dbo].[ProposalEquipmentDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetTypeId]=S.[AssetTypeId],[Cost_Amount]=S.[Cost_Amount],[Cost_Currency]=S.[Cost_Currency],[Description]=S.[Description],[GuaranteedResidual_Amount]=S.[GuaranteedResidual_Amount],[GuaranteedResidual_Currency]=S.[GuaranteedResidual_Currency],[GuaranteedResidualFactor]=S.[GuaranteedResidualFactor],[InterestRate]=S.[InterestRate],[InterimRent_Amount]=S.[InterimRent_Amount],[InterimRent_Currency]=S.[InterimRent_Currency],[InterimRentFactor]=S.[InterimRentFactor],[IsActive]=S.[IsActive],[LocationId]=S.[LocationId],[Number]=S.[Number],[PricingGroupId]=S.[PricingGroupId],[ProposedResidual_Amount]=S.[ProposedResidual_Amount],[ProposedResidual_Currency]=S.[ProposedResidual_Currency],[ProposedResidualFactor]=S.[ProposedResidualFactor],[Quantity]=S.[Quantity],[Rent_Amount]=S.[Rent_Amount],[Rent_Currency]=S.[Rent_Currency],[RentFactor]=S.[RentFactor],[TotalCost_Amount]=S.[TotalCost_Amount],[TotalCost_Currency]=S.[TotalCost_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VendorId]=S.[VendorId]
WHEN NOT MATCHED THEN
	INSERT ([AssetTypeId],[Cost_Amount],[Cost_Currency],[CreatedById],[CreatedTime],[Description],[GuaranteedResidual_Amount],[GuaranteedResidual_Currency],[GuaranteedResidualFactor],[InterestRate],[InterimRent_Amount],[InterimRent_Currency],[InterimRentFactor],[IsActive],[LocationId],[Number],[PricingGroupId],[ProposalExhibitId],[ProposedResidual_Amount],[ProposedResidual_Currency],[ProposedResidualFactor],[Quantity],[Rent_Amount],[Rent_Currency],[RentFactor],[TotalCost_Amount],[TotalCost_Currency],[VendorId])
    VALUES (S.[AssetTypeId],S.[Cost_Amount],S.[Cost_Currency],S.[CreatedById],S.[CreatedTime],S.[Description],S.[GuaranteedResidual_Amount],S.[GuaranteedResidual_Currency],S.[GuaranteedResidualFactor],S.[InterestRate],S.[InterimRent_Amount],S.[InterimRent_Currency],S.[InterimRentFactor],S.[IsActive],S.[LocationId],S.[Number],S.[PricingGroupId],S.[ProposalExhibitId],S.[ProposedResidual_Amount],S.[ProposedResidual_Currency],S.[ProposedResidualFactor],S.[Quantity],S.[Rent_Amount],S.[Rent_Currency],S.[RentFactor],S.[TotalCost_Amount],S.[TotalCost_Currency],S.[VendorId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
