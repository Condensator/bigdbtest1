SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateIncomeSchedulesFromAVH]
(
@LeaseFinanceId  BIGINT,
@SourceModeule VARCHAR(100),
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET,
@IsBookDepFromSyndication BIT,
@isForOverTerm BIT
)
AS
BEGIN
	SET NOCOUNT ON;

	CREATE TABLE #AVHDetails(
		AssetIncomeScheduleId BIGINT NOT NULL,
		LeaseIncomeScheduleId BIGINT NOT NULL,
		BeginBookValue_Amount DECIMAL(16,2) NOT NULL,
		EndBookValue_Amount DECIMAL(16,2),
		Value_Amount DECIMAL(16,2) NOT NULL,
		IsLessorOwned BIT NOT NULL,
		IsForUpdate BIT NOT NULL
	)	

	SELECT 
		IncomeDate, 
		AssetId, 
		BeginBookValue_Amount, 
		EndBookValue_Amount,
		Value_Amount, 
		IsLessorOwned, 
		IsAccounted, 
		SourceModule
	INTO #AssetValueHistoryInfo
	FROM  dbo.AssetValueHistories WITH (FORCESEEK)
	WHERE SourceModuleId = @LeaseFinanceId AND IsSchedule = 1

	SELECT 
		AIS.Id,
		LI.Id AS LeaseIncomeScheduleId,
		AIS.AssetId,
		LI.IncomeDate,
		LI.IsSchedule,
		LI.IsLessorOwned, 
		LI.IsAccounting,
		AIS.OperatingBeginNetBookValue_Amount,
		AIS.OperatingEndNetBookValue_Amount,
		AIS.Depreciation_Amount
	INTO #AssetIncomeDetails
	FROM dbo.LeaseIncomeSchedules LI WITH (FORCESEEK)
	INNER JOIN dbo.AssetIncomeSchedules AIS WITH (FORCESEEK)
		ON AIS.LeaseIncomeScheduleId = LI.Id AND LI.LeaseFinanceId = @LeaseFinanceId
	WHERE AIS.IsActive = 1 AND LI.AdjustmentEntry=0 

	IF((@SourceModeule = 'FixedTermDepreciation' AND  @IsBookDepFromSyndication = 1) OR @isForOverTerm=1)
	BEGIN
		CREATE TABLE #SourceModules (SourceModuleName NVARCHAR(25));

		IF(@isForOverTerm=1)
			INSERT INTO #SourceModules VALUES ('ResidualRecapture'),('OTPDepreciation')
		ELSE
			INSERT INTO #SourceModules VALUES ('FixedTermDepreciation')

		SELECT 
			IncomeDate, 
			AssetId, 
			SUM(BeginBookValue_Amount) BeginBookValue_Amount, 
			SUM(EndBookValue_Amount) EndBookValue_Amount,
			SUM(Value_Amount) Value_Amount, 
			CAST(1 AS BIT) AS IsLessorOwned  
		INTO #AVHSummary 
		FROM #AssetValueHistoryInfo WHERE SourceModule in (SELECT SourceModuleName FROM #SourceModules) 
			AND IsLessorOwned=1
		GROUP BY AssetId,IncomeDate
		
		CREATE NONCLUSTERED INDEX [IX_AssetId] ON #AVHSummary ([AssetId])

		INSERT INTO #AVHSummary(IncomeDate, AssetId, BeginBookValue_Amount, EndBookValue_Amount, Value_Amount, IsLessorOwned) 
		SELECT
			IncomeDate, 
			AssetId, 
			SUM(BeginBookValue_Amount) BeginBookValue_Amount, 
			SUM(EndBookValue_Amount) EndBookValue_Amount,
			SUM(Value_Amount) Value_Amount, 
			CAST(0 AS BIT) AS IsLessorOwned  
		FROM #AssetValueHistoryInfo WHERE SourceModule in (SELECT SourceModuleName FROM #SourceModules) 
			AND IsLessorOwned=0 AND IsAccounted=0
		GROUP BY AssetId,IncomeDate

		INSERT INTO #AVHDetails(AssetIncomeScheduleId, LeaseIncomeScheduleId, BeginBookValue_Amount, EndBookValue_Amount, Value_Amount, IsLessorOwned, IsForUpdate)
		SELECT 
			AIS.Id,
			AIS.LeaseIncomeScheduleId,
			AVH.BeginBookValue_Amount,
			AVH.EndBookValue_Amount,
		    AVH.Value_Amount,
			CAST(1 AS BIT),
			CAST(1 AS BIT)
		FROM #AssetIncomeDetails AIS
		INNER JOIN #AVHSummary AVH 
			ON AVH.AssetId = AIS.AssetId AND AIS.IncomeDate = AVH.IncomeDate
		WHERE AIS.IsSchedule = 1 
			AND AIS.IsLessorOwned = 1
			AND AVH.IsLessorOwned = 1

		INSERT INTO #AVHDetails(AssetIncomeScheduleId, LeaseIncomeScheduleId, BeginBookValue_Amount, EndBookValue_Amount, Value_Amount, IsLessorOwned, IsForUpdate)
		SELECT 
			AIS.Id,
			AIS.LeaseIncomeScheduleId,
			AVH.BeginBookValue_Amount,
			AVH.EndBookValue_Amount,
		    AVH.Value_Amount,
			CAST(0 AS BIT),
			CAST(1 AS BIT)
		FROM  #AssetIncomeDetails AIS
			INNER JOIN #AVHSummary AVH 
				ON AVH.AssetId = AIS.AssetId AND AIS.IncomeDate = AVH.IncomeDate
		WHERE AIS.IsSchedule = 1 
			AND AIS.IsAccounting = 0 
			AND AIS.IsLessorOwned = 0
			AND AVH.IsLessorOwned = 0

		INSERT INTO #AVHDetails(AssetIncomeScheduleId, LeaseIncomeScheduleId, BeginBookValue_Amount, EndBookValue_Amount, Value_Amount, IsLessorOwned, IsForUpdate)
		SELECT 
			AIS.Id,
			AIS.LeaseIncomeScheduleId,
			AIS.OperatingBeginNetBookValue_Amount,
			AIS.OperatingEndNetBookValue_Amount,
		    AIS.Depreciation_Amount,
			AIS.IsLessorOwned,
			CAST(0 AS BIT)
		FROM #AssetIncomeDetails AIS 
		LEFT JOIN #AVHDetails AVH ON AIS.Id = AVH.AssetIncomeScheduleId 
		WHERE AVH.AssetIncomeScheduleId IS NULL 

		/* Updating LI first in order to avoid deadlocks */
		UPDATE dbo.LeaseIncomeSchedules
		SET OperatingBeginNetBookValue_Amount = L.BeginBookValue,
			OperatingEndNetBookValue_Amount = L.EndNetBookValue,
			Depreciation_Amount = L.Depreciation_Amount
		FROM LeaseIncomeSchedules LI WITH (FORCESEEK)
		JOIN 
		(
			SELECT 
				LeaseIncomeScheduleId, IsLessorOwned,
				SUM(BeginBookValue_Amount) AS BeginBookValue,
				SUM(EndBookValue_Amount) AS EndNetBookValue,
				SUM(Value_Amount) AS Depreciation_Amount
			FROM #AVHDetails GROUP BY LeaseIncomeScheduleId, IsLessorOwned
		) L 
		ON LI.Id = L.LeaseIncomeScheduleId AND LI.IsLessorOwned = L.IsLessorOwned

		UPDATE dbo.AssetIncomeSchedules SET
			OperatingBeginNetBookValue_Amount = AVH.BeginBookValue_Amount,
			OperatingEndNetBookValue_Amount = AVH.EndBookValue_Amount,
			Depreciation_Amount = AVH.Value_Amount
		FROM #AVHDetails AVH WHERE AssetIncomeSchedules.Id=AVH.AssetIncomeScheduleId AND IsForUpdate=1
		
	END
	ELSE
	BEGIN

		SELECT 
			IncomeDate, 
			AssetId, 
			SUM(BeginBookValue_Amount) BeginBookValue_Amount, 
			SUM(EndBookValue_Amount) EndBookValue_Amount,
			SUM(Value_Amount) Value_Amount, 
			CAST(1 AS BIT) AS IsLessorOwned
		INTO #AVHSummaryInfo 
		FROM #AssetValueHistoryInfo 
		WHERE SourceModule=@SourceModeule and IsLessorOwned=1
		GROUP BY AssetId,IncomeDate
		
		INSERT INTO #AVHSummaryInfo (
			IncomeDate, 
			AssetId, 
			BeginBookValue_Amount,
			EndBookValue_Amount,
			Value_Amount,
			IsLessorOwned
		)
		SELECT 
			IncomeDate, 
			AssetId, 
			SUM(BeginBookValue_Amount), 
			SUM(EndBookValue_Amount),
			SUM(Value_Amount), 
			CAST(0 AS BIT)  
		FROM #AssetValueHistoryInfo 
		WHERE SourceModule=@SourceModeule and IsLessorOwned=0 AND IsAccounted = 0 
		GROUP BY AssetId,IncomeDate

		CREATE NONCLUSTERED INDEX [IX_AssetId] ON #AVHSummaryInfo ([AssetId])
		
		INSERT INTO #AVHDetails(AssetIncomeScheduleId, LeaseIncomeScheduleId, BeginBookValue_Amount, EndBookValue_Amount, Value_Amount, IsLessorOwned, IsForUpdate)
		SELECT 
			AIS.Id,
			AIS.LeaseIncomeScheduleId,
			AVH.BeginBookValue_Amount,
			AVH.EndBookValue_Amount,
		    AVH.Value_Amount,
			CAST(1 AS BIT),
			CAST(1 AS BIT)
		FROM #AssetIncomeDetails AIS
			INNER JOIN #AVHSummaryInfo AVH 
				ON AVH.AssetId = AIS.AssetId AND AIS.IncomeDate = AVH.IncomeDate
		WHERE AIS.IsSchedule = 1 
			AND AIS.IsLessorOwned = 1
			AND AVH.IsLessorOwned = 1

		INSERT INTO #AVHDetails(AssetIncomeScheduleId, LeaseIncomeScheduleId, BeginBookValue_Amount, EndBookValue_Amount, Value_Amount, IsLessorOwned, IsForUpdate)
		SELECT 
			AIS.Id,
			AIS.LeaseIncomeScheduleId,
			AVH.BeginBookValue_Amount,
			AVH.EndBookValue_Amount,
		    AVH.Value_Amount,
			CAST(0 AS BIT),
			CAST(1 AS BIT)
		FROM #AssetIncomeDetails AIS
			INNER JOIN #AVHSummaryInfo AVH 
				ON AVH.AssetId = AIS.AssetId AND AIS.IncomeDate = AVH.IncomeDate
		WHERE AIS.IsSchedule = 1 
			AND AIS.IsLessorOwned = 0
			AND AVH.IsLessorOwned = 0
			AND AIS.IsAccounting = 0

		INSERT INTO #AVHDetails(AssetIncomeScheduleId, LeaseIncomeScheduleId, BeginBookValue_Amount, EndBookValue_Amount, Value_Amount, IsLessorOwned, IsForUpdate)
		SELECT 
			AIS.Id,
			AIS.LeaseIncomeScheduleId,
			AIS.OperatingBeginNetBookValue_Amount,
			AIS.OperatingEndNetBookValue_Amount,
		    AIS.Depreciation_Amount,
			AIS.IsLessorOwned,
			CAST(0 AS BIT)
		FROM #AssetIncomeDetails AIS 
		LEFT JOIN #AVHDetails AVH ON AIS.Id = AVH.AssetIncomeScheduleId 
		WHERE AVH.AssetIncomeScheduleId IS NULL 
		
		/* Updating LI first in order to avoid deadlocks */
		UPDATE dbo.LeaseIncomeSchedules
		SET OperatingBeginNetBookValue_Amount = L.BeginBookValue,
			OperatingEndNetBookValue_Amount = L.EndNetBookValue,
			Depreciation_Amount = L.Depreciation_Amount
		FROM LeaseIncomeSchedules LI WITH (FORCESEEK)
		JOIN 
		(
			SELECT 
				LeaseIncomeScheduleId, IsLessorOwned,
				SUM(BeginBookValue_Amount) AS BeginBookValue,
				SUM(EndBookValue_Amount) AS EndNetBookValue,
				SUM(Value_Amount) AS Depreciation_Amount
			FROM #AVHDetails GROUP BY LeaseIncomeScheduleId, IsLessorOwned
		) L
		ON LI.Id = L.LeaseIncomeScheduleId  And LI.IsLessorOwned = L.IsLessorOwned

		UPDATE dbo.AssetIncomeSchedules
			SET
			OperatingBeginNetBookValue_Amount = AVH.BeginBookValue_Amount,
			OperatingEndNetBookValue_Amount = AVH.EndBookValue_Amount,
			Depreciation_Amount = AVH.Value_Amount
		FROM #AVHDetails AVH WHERE AssetIncomeSchedules.Id=AVH.AssetIncomeScheduleId AND IsForUpdate=1
	END
END

GO
