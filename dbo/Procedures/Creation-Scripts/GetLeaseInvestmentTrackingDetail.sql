SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[GetLeaseInvestmentTrackingDetail]
(
	@ContractId BIGINT NULL,
	@EffectiveDate DATETIME NULL,
	@ModuleName NVARCHAR(50)
)
AS
SET NOCOUNT ON;

IF(@ModuleName = 'LeaseBooking')
BEGIN
	SELECT 
		Investment, 
		InvestmentDate 
	FROM LeaseInvestmentTrackings WITH (FORCESEEK) 
	WHERE ContractId = @ContractId
		  AND IsActive = 1
		  AND InvestmentDate > @EffectiveDate
END
IF(@ModuleName = 'PayoffSyndication')
BEGIN
	SELECT 
		Investment, 
		InvestmentDate 
	FROM LeaseInvestmentTrackings WITH (FORCESEEK) 
	WHERE ContractId = @ContractId
		  AND IsActive = 1
		  AND InvestmentDate > @EffectiveDate
		  AND IsLessorOwned = 0
END
IF(@ModuleName = 'ReAccuralLeaseIncome')
BEGIN
	SELECT 
		Investment, 
		InvestmentDate 
	FROM LeaseInvestmentTrackings WITH (FORCESEEK) 
	WHERE ContractId = @ContractId
		  AND IsActive = 1
		  AND IsLessorOwned = 0
END
IF(@ModuleName = 'ReceivableForTransfer' OR @ModuleName = 'PayoffReversal')
BEGIN
	SELECT 
		Investment, 
		InvestmentDate 
	FROM LeaseInvestmentTrackings WITH (FORCESEEK) 
	WHERE ContractId = @ContractId
		  AND IsActive = 1
		  AND InvestmentDate >= @EffectiveDate
END

GO
