SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ValidateVATTaxReversalDownPaymentReceivables]
(
	@JobStepInstanceId												BIGINT,
	@ReceivableTaxType_VAT											NVARCHAR(10),
	@ReceivableEntityType_CT										NVARCHAR(10),
	@PaymentType_DownPayment										NVARCHAR(20),
	@LeasePurchaseOption_HirePurchase								NVARCHAR(2),
	@SalesTaxInvalidReceivableCode_DownPaymentHirePurchaseContract	NVARCHAR(100),
	@SalesTaxInvalidReceivableCode_IsTaxIncludedForDownPaymentNonHirePurchaseContract NVARCHAR(100)		
)
AS
BEGIN

UPDATE RRB
	SET ErrorCode = CASE WHEN DPT.LeaseType = @LeasePurchaseOption_HirePurchase THEN 
						@SalesTaxInvalidReceivableCode_DownPaymentHirePurchaseContract
					 WHEN LFD.IsDownpaymentIncludesTax = 1 THEN
						@SalesTaxInvalidReceivableCode_IsTaxIncludedForDownPaymentNonHirePurchaseContract
					 END
FROM ReversalReceivableDetail_Extract RRB
INNER JOIN Contracts C ON RRB.ContractId = C.Id
INNER JOIN DealProductTypes DPT ON C.DealProductTypeId = DPT.Id
INNER JOIN LeaseFinances LF ON C.Id = LF.ContractId AND LF.IsCurrent = 1
INNER JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
LEFT JOIN LeasePaymentSchedules LPS ON RRB.PaymentScheduleId = LPS.Id 
	AND LFD.Id = LPS.LeaseFinanceDetailId
WHERE ReceivableTaxType = @ReceivableTaxType_VAT AND IsVertexSupported = 0 
	AND ErrorCode IS NULL AND EntityType = @ReceivableEntityType_CT 
	AND ReceivableTaxId IS NOT NULL AND JobStepInstanceId = @JobStepInstanceId
	AND RRB.PaymentScheduleId IS NOT NULL AND LPS.PaymentType = @PaymentType_DownPayment
	AND (LFD.IsDownpaymentIncludesTax = 1 OR DPT.LeaseType = @LeasePurchaseOption_HirePurchase)
;		

END

GO
