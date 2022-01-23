SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UpdateLeaseIsRenewalFlag]
(
	@JobStepInstanceId	BIGINT
)
AS
BEGIN

UPDATE TD SET TD.IsRenewal = LPS.IsRenewal
FROM SalesTaxReceivableDetailExtract TD
JOIN LeasePaymentSchedules LPS ON TD.PaymentScheduleId = LPS.Id AND LPS.IsActive = 1
JOIN Contracts C ON TD.ContractId = C.Id
WHERE C.ContractType = 'Lease';

END

GO
