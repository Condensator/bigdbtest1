SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[InsertSalesTaxReceivableSKUDetail]
(  
	@CreatedById		BIGINT,
	@CreatedTime		DATETIMEOFFSET,
	@JobStepInstanceId	BIGINT
)  
AS   
SET NOCOUNT ON;  
  
BEGIN  

INSERT INTO SalesTaxReceivableSKUDetailExtract
(
     ReceivableDetailId 
	,ReceivableSKUId 
	,AssetId 
	,AssetSKUId 
	,ContractId
	,ExtendedPrice 
	,AmountBilledToDate
	,JobStepInstanceId 
)
Select
  RDE.ReceivableDetailId
 ,RSK.Id as ReceivableSKUId
 ,RDE.AssetId
 ,RSK.AssetSKUId
 ,RDE.ContractId
 ,RSK.Amount_Amount as ExtendedPrice
 ,0
 ,@JobStepInstanceId
From SalesTaxReceivableDetailExtract RDE
INNER JOIN ReceivableSKUs RSK ON RDE.ReceivableDetailId = RSK.ReceivableDetailId
Where RDE.JobStepInstanceId = @JobStepInstanceId AND RDE.IsAssessSalesTaxAtSKULevel = 1
AND RSK.PreCapitalizationRent_Amount = 0.00;

INSERT INTO SalesTaxReceivableSKUDetailExtract
(
     ReceivableDetailId 
	,ReceivableSKUId 
	,AssetId 
	,AssetSKUId 
	,ContractId
	,ExtendedPrice 
	,AmountBilledToDate
	,JobStepInstanceId 
)
Select
  RDE.ReceivableDetailId
 ,RSK.Id as ReceivableSKUId
 ,RDE.AssetId
 ,RSK.AssetSKUId
 ,RDE.ContractId
 ,RSK.PreCapitalizationRent_Amount as ExtendedPrice
 ,0
 ,@JobStepInstanceId
From SalesTaxReceivableDetailExtract RDE
INNER JOIN ReceivableSKUs RSK ON RDE.ReceivableDetailId = RSK.ReceivableDetailId
Where RDE.JobStepInstanceId = @JobStepInstanceId AND RDE.IsAssessSalesTaxAtSKULevel = 1
AND RSK.PreCapitalizationRent_Amount <> 0.00;

END

GO
