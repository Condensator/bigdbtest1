SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetInProgressTaxAssessingReceivablesForPayOffAsset]
(
	@AssetIds AssetIdCollection READONLY,
	@ContractId BIGINT,
	@PayoffEffectiveDate DATETIMEOFFSET,
	@CTEntityType NVARCHAR(4),
	@JobStatus NVARCHAR (38),
	@UnKnownSourceTable NVARCHAR (40),
	@JobId BIGINT = 0 OUTPUT
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET @JobId = (SELECT TOP(1) J.Id 
	FROM Receivables R
		INNER JOIN ReceivableDetails RD ON R.Id = RD.ReceivableId
		INNER JOIN LeasePaymentSchedules LPS ON R.PaymentScheduleId = LPS.Id AND R.SourceTable = @UnKnownSourceTable
		INNER JOIN @AssetIds A ON RD.AssetId = A.AssetId
		INNER JOIN SalesTaxReceivableDetailExtract STR ON RD.Id = STR.ReceivableDetailId AND RD.AssetId  = STR.AssetId
		INNER JOIN JobStepInstances JSI ON STR.JobStepInstanceId = JSI.Id
		INNER JOIN JobInstances JI ON JSI.JobInstanceId = JI.Id
		INNER JOIN Jobs J ON JI.JobId = J.Id
	WHERE LPS.StartDate >= @PayoffEffectiveDate
	      AND JI.Status = @JobStatus
	      AND R.EntityId = @ContractId
	      AND R.EntityType = @CTEntityType
	      AND R.IsActive = 1
	      AND RD.IsActive = 1
	GROUP BY J.Id)

END

GO
