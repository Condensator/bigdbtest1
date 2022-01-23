SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE [dbo].[ExtractReceivablesForWithHoldingTaxAssessment]
(
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET,
@FilterOption  NVARCHAR(5),
@EntityId BIGINT = NULL,
@EntityType NVARCHAR(4),
@ProcessThroughDate DATETIME,
@JobStepInstanceId BIGINT,
@InvoiceSensitive BIT,
@LegalEntityIds NVARCHAR(MAX),
@AllFilterOption NVARCHAR(5),
@CustomerEntityType NVARCHAR(5),
@ContractEntityType NVARCHAR(5)
)AS
BEGIN
SET NOCOUNT ON
--DECLARE
--	@CreatedById BIGINT = 40413,
--	@CreatedTime DATETIMEOFFSET = sysdatetimeoffset(),
--  @FilterOption NVARCHAR(5) = 'One',
--	@EntityID BIGINT = null,
--  @EntityType NVARCHAR(MAX) = '_',
--	@ProcessThroughDate DATETIMEOFFSET = sysdatetimeoffset(),
--	@JobStepInstanceId BIGINT = 1234,
--  @InvoiceSensitive BIT = 0,
--  @LegalEntityIds NVARCHAR(MAX) = '1,10020,20028,20031,20039,20048,20088,20089,20090,20091,20092,20093,20094,20095,20096,20097,20098,20099,20100,20101,20102,20103,20104',
--  @AllFilterOption NVARCHAR(5) = 'All',
--  @CustomerEntityType NVARCHAR(5) = 'CU',
--  @ContractEntityType NVARCHAR(5) = 'CT'

CREATE TABLE #Contracts(
ContractId BIGINT,
InvoiceLeadDays INT
)
CREATE CLUSTERED INDEX IDX_CONTRACTINFO ON #Contracts(ContractId)


SELECT Id 
	INTO #LegalEntities
	FROM dbo.ConvertCSVToBigIntTable(@LegalEntityIds,',')

IF(@EntityType = @ContractEntityType)
BEGIN
		INSERT INTO WithHoldingTaxExtracts(EntityId, EntityType, ReceivableId, JobStepInstanceId, CreatedById, CreatedTime, IsSubmitted)
		SELECT receivable.EntityId, receivable.EntityType, receivable.Id, @JobStepInstanceId, @CreatedById, @CreatedTime, 0
		FROM Receivables receivable
		JOIN #LegalEntities le ON receivable.LegalEntityId = le.ID
		JOIN ContractBillings cb ON cb.Id = receivable.EntityId
			AND receivable.EntityType = @ContractEntityType
		LEFT JOIN ReceivableWithholdingTaxDetails wht on receivable.Id = wht.ReceivableId AND wht.IsActive = 1
		WHERE (receivable.EntityId = @EntityId OR @FilterOption = @AllFilterOption)
		AND ((@InvoiceSensitive = 0 AND receivable.DueDate <= @ProcessThroughDate) 
			OR (@InvoiceSensitive = 1 AND receivable.DueDate <= (DATEADD(DD, cb.InvoiceLeadDays, @ProcessThroughDate))))
		AND receivable.IsActive = 1
		AND receivable.IsDSL = 0
		AND receivable.IsDummy = 0
		AND cb.IsActive = 1
		AND wht.Id IS NULL
END
ELSE
BEGIN
		INSERT INTO #Contracts(ContractId, InvoiceLeadDays)
		SELECT lf.ContractId, cb.InvoiceLeaddays FROM LeaseFinances lf 
			JOIN ContractBillings cb ON lf.ContractId = cb.Id
		WHERE IsCurrent = 1 AND (lf.CustomerId = @EntityId OR @FilterOption = @AllFilterOption) AND cb.IsActive = 1
		UNION ALL
		SELECT lf.ContractId, cb.InvoiceLeaddays FROM LoanFinances lf 
			JOIN ContractBillings cb ON lf.ContractId = cb.Id
		WHERE IsCurrent = 1 AND (lf.CustomerId = @EntityId OR @FilterOption = @AllFilterOption) AND cb.IsActive = 1
		UNION ALL
		SELECT lf.ContractId, cb.InvoiceLeaddays FROM LeveragedLeases lf 
			JOIN ContractBillings cb ON lf.ContractId = cb.Id
		WHERE IsCurrent = 1 AND (lf.CustomerId = @EntityId OR @FilterOption = @AllFilterOption) AND cb.IsActive = 1

		INSERT INTO WithHoldingTaxExtracts(EntityId, EntityType, ReceivableId, JobStepInstanceId, CreatedById, CreatedTime, IsSubmitted)
		SELECT receivable.EntityId, receivable.EntityType, receivable.Id, @JobStepInstanceId, @CreatedById, @CreatedTime, 0
		FROM Receivables receivable
		JOIN #LegalEntities le ON receivable.LegalEntityId = le.ID
		JOIN #Contracts c ON receivable.EntityId = c.ContractId
			AND receivable.EntityType = @ContractEntityType
		LEFT JOIN ReceivableWithholdingTaxDetails wht on receivable.Id = wht.ReceivableId AND wht.IsActive = 1
		WHERE ((@InvoiceSensitive = 0 AND receivable.DueDate <= @ProcessThroughDate) 
			OR (@InvoiceSensitive = 1 AND receivable.DueDate <= (DATEADD(DD, c.InvoiceLeadDays, @ProcessThroughDate))))
		AND receivable.IsActive = 1
		AND receivable.IsDSL = 0
		AND receivable.IsDummy = 0
		AND wht.Id IS NULL

		INSERT INTO WithHoldingTaxExtracts(EntityId, EntityType, ReceivableId, JobStepInstanceId, CreatedById, CreatedTime, IsSubmitted)
		SELECT receivable.EntityId, receivable.EntityType, receivable.Id, @JobStepInstanceId, @CreatedById, @CreatedTime, 0
		FROM Receivables receivable
		JOIN #LegalEntities le ON receivable.LegalEntityId = le.ID
		JOIN Customers c ON receivable.EntityId = c.Id
			AND receivable.EntityType = @CustomerEntityType
		LEFT JOIN ReceivableWithholdingTaxDetails wht on receivable.Id = wht.ReceivableId AND wht.IsActive = 1
		WHERE (receivable.EntityId = @EntityId OR @FilterOption = @AllFilterOption)
		AND ((@InvoiceSensitive = 0 AND receivable.DueDate <= @ProcessThroughDate) 
			OR (@InvoiceSensitive = 1 AND receivable.DueDate <= (DATEADD(DD, c.InvoiceLeadDays, @ProcessThroughDate))))
		AND receivable.IsActive = 1
		AND receivable.IsDSL = 0
		AND receivable.IsDummy = 0
		AND wht.Id IS NULL
		
END

DROP TABLE #Contracts
DROP TABLE #LegalEntities

SET NOCOUNT OFF
END

GO
