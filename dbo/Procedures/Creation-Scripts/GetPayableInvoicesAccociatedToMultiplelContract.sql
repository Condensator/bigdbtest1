SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Proc [dbo].[GetPayableInvoicesAccociatedToMultiplelContract]
(
	@LegalEntityId BIGINT,
	@VendorId BIGINT
)
As
Begin
Select Distinct payableinvoice.Id As 'payableInvoiceId'  
From PayableInvoices payableinvoice  
Join  PayableInvoiceAssets payableInvoiceAsset  
	On payableInvoice.Id = payableInvoiceAsset.PayableInvoiceId  
	And payableInvoice.VendorId = @VendorId
	And payableInvoice.Status = 'Completed'  
	And payableInvoice.ContractId Is Null
	And payableInvoice.LegalEntityId = @LegalEntityId
Join  LeaseAssets leaseAssetpayableInvoiceAsset  
	On payableInvoiceAsset.AssetId = leaseAssetpayableInvoiceAsset.AssetId  
	And payableInvoiceAsset.IsActive = 1
Join  LeaseFinances leaseFinancepayableInvoiceAsset  
	On leaseAssetpayableInvoiceAsset.LeaseFinanceId = leaseFinancepayableInvoiceAsset.Id  
	And leaseAssetpayableInvoiceAsset.IsActive = 1 
	And leaseFinancepayableInvoiceAsset.BookingStatus != 'Inactive' 
	And leaseFinancepayableInvoiceAsset.IsCurrent = 1  
UNION ALL
select Distinct payableinvoice.Id as 'payableInvoiceId'  
from PayableInvoices payableinvoice  
Join  PayableInvoiceOtherCosts payableInvoiceOtherCost  
	On payableInvoice.Id = payableInvoiceOtherCost.PayableInvoiceId
	And payableInvoice.VendorId = @VendorId
	And payableInvoice.ContractId Is Null  
	And payableInvoice.Status = 'Completed'  
	And payableInvoice.LegalEntityId = @LegalEntityId	
	And payableInvoiceOtherCost.IsActive = 1  
Join  LeaseSpecificCostAdjustments  
	On payableInvoiceOtherCost.Id = LeaseSpecificCostAdjustments.PayableInvoiceOtherCostId  
	And LeaseSpecificCostAdjustments.IsActive = 1  
Join  LeaseFinances leaseFinancePayableInvoiceOtherCost  
	On LeaseSpecificCostAdjustments.LeaseFinanceId = leaseFinancePayableInvoiceOtherCost.Id  
	And leaseFinancePayableInvoiceOtherCost.BookingStatus != 'Inactive' 
	And leaseFinancePayableInvoiceOtherCost.IsCurrent = 1 
End

GO
