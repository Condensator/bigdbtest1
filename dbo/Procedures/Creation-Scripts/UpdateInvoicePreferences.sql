SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UpdateInvoicePreferences] (
	@JobStepInstanceId BIGINT,
	@InvoicePreference NVARCHAR(20),
	@InvoicePreference_Unknown NVARCHAR(100)
	)
AS
BEGIN
	SET NOCOUNT ON;

	/*Table used for determining contract Preference */
	CREATE TABLE #ContractPreferenceToUse (
		ReceivableId BIGINT,
		ContractId BIGINT,
		ContractInvoicePreference NVARCHAR(50)
	)

	CREATE NONCLUSTERED INDEX [IX_ReceivableId] ON [dbo].[#ContractPreferenceToUse] ([ReceivableId], ContractId);

	CREATE TABLE #DistinctContractUpdates(
		ContractId BIGINT,
		ReceivableId BIGINT,
		ReceivableDueDate DATE,
		ReceivableTypeId BIGINT
	)

	CREATE NONCLUSTERED INDEX IX_DistinctContract ON #DistinctContractUpdates(ContractId)

	INSERT INTO #DistinctContractUpdates(ContractId, ReceivableId, ReceivableDueDate, ReceivableTypeId)
	SELECT ContractId,
		ReceivableId,
		ReceivableDueDate,
		ReceivableTypeId
	FROM InvoiceReceivableDetails_Extract
	WHERE JobStepInstanceId = @JobStepInstanceId AND IsActive=1
		AND ContractId IS NOT NULL
	GROUP BY ContractId,
		ReceivableId,
		ReceivableDueDate,
		ReceivableTypeId

	CREATE TABLE #EffectiveDateForPreferenceContractUpdates(
		ContractId BIGINT,
		ReceivableId BIGINT,
		EffectiveDate DATE,
		ReceivableTypeId BIGINT
	)

	CREATE NONCLUSTERED INDEX IX_EffectiveIndex ON #EffectiveDateForPreferenceContractUpdates(ContractId) INCLUDE (ReceivableId)

	INSERT INTO #EffectiveDateForPreferenceContractUpdates(ContractId, ReceivableId, ReceivableTypeId, EffectiveDate)
	SELECT RecContract.ContractId,
			RecContract.ReceivableId,
			RecContract.ReceivableTypeID,
			MAX(CBP.EffectiveFromDate) EffectiveDate
		FROM #DistinctContractUpdates AS RecContract
		INNER JOIN ContractBillings AS CB ON RecContract.ContractId = CB.Id
		INNER JOIN ContractBillingPreferences AS CBP ON CB.Id = CBP.ContractBillingId
			AND CBP.IsActive = 1
			AND CBP.ReceivableTypeId = RecContract.ReceivableTypeId
			AND CBP.EffectiveFromDate <= RecContract.ReceivableDueDate
		GROUP BY RecContract.ContractId,
			RecContract.ReceivableId,
			RecContract.ReceivableTypeId


	/* Getting Contract Preference */
	INSERT INTO #ContractPreferenceToUse (
		ReceivableId,
		ContractId,
		ContractInvoicePreference
		)
	SELECT EDP.ReceivableID,
		EDP.Contractid,
		CBP.InvoicePreference
	FROM #EffectiveDateForPreferenceContractUpdates AS EDP
	INNER JOIN ContractBillings AS CB ON EDP.ContractId = CB.Id
	INNER JOIN COntractBillingPreferences AS CBP ON CB.Id = CBP.ContractBillingId
		AND CBP.ReceivableTypeId = EDP.ReceivableTypeId
		AND CBP.EffectiveFromDate = EDP.EffectiveDate
		AND CBP.IsActive = 1

	/*Table used for determining Customer Preference */
	CREATE TABLE #CustomerPreferenceToUse (
		ReceivableId BIGINT,
		CustomerId BIGINT,
		CustomerInvoicePreference NVARCHAR(50)
		)

	CREATE NONCLUSTERED INDEX [IX_ReceivableId] ON [dbo].[#CustomerPreferenceToUse] ([ReceivableId], CustomerId);

	WITH CTE_ReceivableCustomer
	AS (
		SELECT CustomerId,
			ReceivableId,
			ReceivableDueDate,
			ReceivableTypeId
		FROM InvoiceReceivableDetails_Extract
		WHERE JobStepInstanceId = @JobStepInstanceId AND IsActive=1
		GROUP BY CustomerId,
			ReceivableID,
			ReceivableDueDate,
			ReceivableTypeId
		),
	CTE_EffectiveDateForPreference
	AS (
		SELECT RecCust.CustomerId,
			RecCust.ReceivableId,
			RecCust.ReceivableTypeId,
			MAX(CBP.EffectiveFromDate) EffectiveDate
		FROM CTE_ReceivableCustomer AS RecCust
		INNER JOIN CustomerBillingPreferences AS CBP ON RecCust.CustomerId = CBP.CustomerId
			AND CBP.IsActive = 1
			AND CBP.ReceivableTypeId = RecCust.ReceivableTypeId
			AND CBP.EffectiveFromDate <= RecCust.ReceivableDueDate
		GROUP BY RecCust.CustomerId,
			RecCust.ReceivableId,
			RecCust.ReceivableTypeId
		)
	/* Getting Contract Preference */
	INSERT INTO #CustomerPreferenceToUse (
		ReceivableId,
		CustomerID,
		CustomerInvoicePreference
		)
	SELECT EDP.ReceivableId,
		EDP.CustomerId,
		CBP.InvoicePreference
	FROM CTE_EffectiveDateForPreference AS EDP
	INNER JOIN CustomerBillingPreferences AS CBP ON EDP.CustomerId = CBP.CustomerId
		AND CBP.ReceivableTypeId = EDP.ReceivableTypeId
		AND CBP.EffectiveFromDate = EDP.EffectiveDate
	GROUP BY EDP.ReceivableId,
		EDP.CustomerId,
		CBP.InvoicePreference

	UPDATE IRD
	SET InvoicePreference = CASE 
			WHEN ContractPreference.ContractInvoicePreference != @InvoicePreference_Unknown
				THEN ContractPreference.ContractInvoicePreference
			WHEN CustomerPreference.CustomerInvoicePreference != @InvoicePreference_Unknown
				THEN CustomerPreference.CustomerInvoicePreference
			ELSE @InvoicePreference
			END
	FROM InvoiceReceivableDetails_Extract IRD
	LEFT JOIN #ContractPreferenceToUse ContractPreference ON IRD.ContractId = ContractPreference.ContractId AND IRD.ReceivableId = ContractPreference.ReceivableId
	LEFT JOIN #CustomerPreferenceToUse CustomerPreference ON IRD.CustomerId = CustomerPreference.CustomerId	AND IRD.ReceivableId = CustomerPreference.ReceivableId
	WHERE IRD.JobStepInstanceId = @JobStepInstanceId AND IRD.IsActive=1
END

GO
