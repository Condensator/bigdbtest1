SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[UpdateReceiptWriteDownFlagInReceivableLevel]
(
@ReceivableEntityType_CT					   NVARCHAR(4),
@ContractType_Lease							   NVARCHAR(28),
@ContractType_Loan							   NVARCHAR(28),
@ReceivableType_CapitalLeaseRental			   NVARCHAR(42),
@ReceivableType_OperatingLeaseRental		   NVARCHAR(42),
@ReceivableType_LeaseFloatRateAdj			   NVARCHAR(42),
@ReceivableType_LoanInterest				   NVARCHAR(42),
@ReceivableType_LoanPrincipal				   NVARCHAR(42),
@LeasePaymentType_FixedTerm					   NVARCHAR(56),
@LeasePaymentType_DownPayment				   NVARCHAR(56),
@LeasePaymentType_MaturityPayment			   NVARCHAR(56),
@LeasePaymentType_CustomerGuaranteedResidual   NVARCHAR(56),
@LeasePaymentType_ThirdPartyGuaranteedResidual NVARCHAR(56),
@AssetComponentType_Finance					   NVARCHAR(14),
@BlendedItemBookRecognitionMode_Accrete		   NVARCHAR(40),
@BlendedItemBookRecognitionMode_Amortize	   NVARCHAR(40),
@LoanPaymentType_FixedTerm					   NVARCHAR(36),
@LoanPaymentType_DownPayment				   NVARCHAR(36),
@LeaseContractTypeValues_Operating			   NVARCHAR(36),
@JobStepInstanceId							   BIGINT
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON;
-- Fetch Lease Rental Receivables

UPDATE RD_Extract
	SET IsWritedownReceivable = CASE WHEN RD_Extract.LeaseContractType <> @LeaseContractTypeValues_Operating THEN
									CAST(1 AS BIT)
								WHEN RD_Extract.ReceivableType = @ReceivableType_OperatingLeaseRental AND
									(RD_Extract.NonLeaseComponentAmountApplied 
								   - RD_Extract.PrevNonLeaseComponentAmountAppliedForReApplication) <> 0.00 THEN	
									CAST(1 AS BIT)
								WHEN RD_Extract.ReceivableType = @ReceivableType_LeaseFloatRateAdj AND
								    (RD_Extract.NonLeaseComponentAmountApplied 
								   - RD_Extract.PrevNonLeaseComponentAmountAppliedForReApplication) <> 0.00 THEN	
									CAST(1 AS BIT)
								ELSE
									CAST(0 AS BIT)
								END
FROM (
	SELECT * FROM ReceiptReceivableDetails_Extract
	WHERE JobStepInstanceId = @JobStepInstanceId AND IsWritedownContract = 1
	AND ContractType = @ContractType_Lease
	AND ReceivableType IN
	(
		@ReceivableType_CapitalLeaseRental, @ReceivableType_OperatingLeaseRental, @ReceivableType_LeaseFloatRateAdj
	)
	AND FunderId IS NULL
) RD_Extract
INNER JOIN LeasePaymentSchedules LPS ON RD_Extract.PaymentScheduleId = LPS.Id 
	AND RD_Extract.ContractType = @ContractType_Lease AND LPS.IsActive = 1

WHERE
LPS.PaymentType IN
(
	@LeasePaymentType_FixedTerm, @LeasePaymentType_DownPayment, @LeasePaymentType_MaturityPayment,
	@LeasePaymentType_CustomerGuaranteedResidual, @LeasePaymentType_ThirdPartyGuaranteedResidual
);
UPDATE
RD_Extract
SET
IsWritedownReceivable = 1
FROM (SELECT * FROM ReceiptReceivableDetails_Extract
WHERE JobStepInstanceId = @JobStepInstanceId AND IsWritedownContract = 1
AND FunderId IS NULL) RD_Extract
INNER JOIN Sundries S ON RD_Extract.ReceivableId = S.ReceivableId AND S.IsActive = 1
INNER JOIN BlendedItemDetails BID ON S.Id = BID.SundryId
INNER JOIN BlendedItems BI ON BID.BlendedItemId = BI.Id AND BI.IsActive = 1 AND BI.IsFAS91 = 1
WHERE BI.EndDate >= RD_Extract.NonAccrualDate
AND BI.BookRecognitionMode IN (@BlendedItemBookRecognitionMode_Accrete, @BlendedItemBookRecognitionMode_Amortize)
;
--Fetch Loan Rental Receivables
UPDATE
RD_Extract
SET
IsWritedownReceivable = 1
FROM
(
SELECT * FROM ReceiptReceivableDetails_Extract
WHERE JobStepInstanceId = @JobStepInstanceId AND IsWritedownContract = 1
AND ContractType = @ContractType_Loan
AND ReceivableType IN (@ReceivableType_LoanInterest, @ReceivableType_LoanPrincipal)
AND FunderId IS NULL
) RD_Extract
INNER JOIN LoanPaymentSchedules LPS ON RD_Extract.PaymentScheduleId = LPS.Id AND LPS.IsActive = 1
WHERE LPS.PaymentType IN (@LoanPaymentType_FixedTerm, @LoanPaymentType_DownPayment)
;
END

GO
