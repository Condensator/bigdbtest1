SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ExtractInvoiceOriginationDetails] 
(
	@JobStepInstanceId	BIGINT,
	@CreatedById		BIGINT,
	@ContractType_LeveragedLease NVARCHAR(100),
	@OriginationChannel_Direct NVARCHAR(100),
	@OriginationChannel_Indirect NVARCHAR(100),
	@OriginationChannel_Vendor NVARCHAR(100),
	@ReceivableForTransferApprovalStatus_Approved NVARCHAR(100),
	@SyndicationType_Unknown NVARCHAR(100),
	@SyndicationType_None NVARCHAR(100)
)
AS
BEGIN
	SET NOCOUNT ON;

	WITH CTE_ContractsInUse
	AS (
		SELECT ContractId,
			LegalEntityId,
			IsSyndicated
		FROM InvoiceReceivableDetails_Extract
		WHERE ContractType <> @ContractType_LeveragedLease AND JobStepInstanceId=@JobStepInstanceId AND IsActive=1
		GROUP BY ContractId,
			LegalEntityId,
			IsSyndicated
		),
	CTE_ContractOriginationDetails
	AS (
		SELECT Con.ContractId,
			CASE 
				WHEN LOST.Name IS NULL
					THEN LoanOST.Name
				ELSE LOST.Name
				END OriginationSource,
			CASE 
				WHEN LCO.OriginationSourceId IS NULL
					THEN LoanCO.OriginationSourceId
				ELSE LCO.OriginationSourceId
				END OriginationSourceId,
			CASE 
				WHEN LF.ContractOriginationId IS NOT NULL
					THEN LF.ContractOriginationId
				ELSE LoanF.ContractOriginationId
				END ContractOriginationId
		FROM Contracts C
		INNER JOIN CTE_ContractsInUse Con ON C.Id = Con.ContractId
		LEFT JOIN LeaseFinances LF ON LF.ContractId = C.Id
			AND LF.IsCurrent = 1
		LEFT JOIN ContractOriginations LCO ON LF.ContractOriginationId = LCO.Id
		LEFT JOIN OriginationSourceTypes LOST ON LCO.OriginationSourceTypeId = LOST.Id
		LEFT JOIN LoanFinances LoanF ON LoanF.ContractId = C.Id
			AND LoanF.IsCurrent = 1
		LEFT JOIN ContractOriginations LoanCO ON LoanF.ContractOriginationId = LoanCO.Id
		LEFT JOIN OriginationSourceTypes LoanOST ON LoanCO.OriginationSourceTypeId = LoanOST.Id
		),
	CTE_UpdatedContractOriginationDetails
	AS (
		SELECT ROW_NUMBER() OVER (
				PARTITION BY COD.ContractOriginationId ORDER BY SD.Id
				) AS OriginationServicings,
			COD.*,
			SD.IsPrivateLabel,
			SD.IsCobrand
		FROM CTE_ContractOriginationDetails COD
		LEFT JOIN ContractOriginationServicingDetails COSD ON COD.ContractOriginationId = COSD.ContractOriginationId
		LEFT JOIN ServicingDetails SD ON COSD.ServicingDetailId = SD.Id
			AND SD.IsActive = 1
		),
	CTE_ContractSyndicationDetails
	AS (
		SELECT Con.ContractId,
			ROW_NUMBER() OVER (
				PARTITION BY RFT.Id ORDER BY RFTFS.Id
				) AS SyndicatedFunders,
			@OriginationChannel_Indirect AS OriginationSource,
			RFTFS.FunderId,
			RFT.Id ReceivableForTransferId
		FROM Contracts C
		INNER JOIN CTE_ContractsInUse Con ON C.Id = Con.ContractId
		INNER JOIN ReceivableForTransfers RFT ON C.Id = RFT.ContractId
			AND RFT.ApprovalStatus = @ReceivableForTransferApprovalStatus_Approved
		INNER JOIN ReceivableForTransferFundingSources RFTFS ON RFT.Id = RFTFS.ReceivableForTransferId
			AND RFTFS.IsActive = 1
		WHERE C.SyndicationType <> @SyndicationType_Unknown
			AND C.SyndicationType <> @SyndicationType_None
		),
	CTE_UpdateContractSyndicationDetails
	AS (
		SELECT ROW_NUMBER() OVER (
				PARTITION BY CSD.ReceivableForTransferId ORDER BY RFTS.Id
				) AS SyndicationServicings,
			CSD.*,
			RFTS.IsPrivateLabel,
			RFTS.IsCobrand
		FROM CTE_ContractSyndicationDetails CSD
		INNER JOIN ReceivableForTransferServicings RFTS ON CSD.ReceivableForTransferId = RFTS.ReceivableForTransferId
			AND RFTS.IsActive = 1
		WHERE CSD.SyndicatedFunders = 1
		)
	INSERT INTO InvoiceOriginationSource_Extract (
		JobStepInstanceId,
		ContractId,
		OriginationSource,
		OriginationSourceId,
		CreatedById,
		CreatedTime
		)
	SELECT @JobStepInstanceId,
		C.ContractId,
		CASE 
			WHEN (
					COD.OriginationSource = @OriginationChannel_Vendor
					OR COD.OriginationSource = @OriginationChannel_Indirect
					)
				AND C.IsSyndicated = 0
				AND (
					COD.IsPrivateLabel = 1
					OR COD.IsCobrand = 1
					)
				THEN COD.OriginationSource
			WHEN (
					COD.OriginationSource = @OriginationChannel_Vendor
					OR COD.OriginationSource = @OriginationChannel_Indirect
					)
				AND C.IsSyndicated = 1
				AND COD.IsPrivateLabel = 1
				AND CSD.IsPrivateLabel = 1
				THEN COD.OriginationSource
			WHEN (
					COD.OriginationSource = @OriginationChannel_Vendor
					OR COD.OriginationSource = @OriginationChannel_Indirect
					)
				AND C.IsSyndicated = 1
				AND COD.IsPrivateLabel = 0
				AND CSD.IsPrivateLabel = 0
				THEN @OriginationChannel_Indirect
			WHEN (COD.OriginationSource = @OriginationChannel_Direct)
				AND C.IsSyndicated = 1
				AND CSD.IsPrivateLabel = 0
				THEN @OriginationChannel_Indirect
			ELSE @OriginationChannel_Direct
		END OriginationSource,
		CASE 
			WHEN (
					COD.OriginationSource = @OriginationChannel_Vendor
					OR COD.OriginationSource = @OriginationChannel_Indirect
					)
				AND C.IsSyndicated = 0
				AND (
					COD.IsPrivateLabel = 1
					OR COD.IsCobrand = 1
					)
				THEN COD.OriginationSourceId
			WHEN (
					COD.OriginationSource = @OriginationChannel_Vendor
					OR COD.OriginationSource = @OriginationChannel_Indirect
					)
				AND C.IsSyndicated = 1
				AND COD.IsPrivateLabel = 1
				AND CSD.IsPrivateLabel = 1
				THEN COD.OriginationSourceId
			WHEN (
					COD.OriginationSource = @OriginationChannel_Vendor
					OR COD.OriginationSource = @OriginationChannel_Indirect
					)
				AND C.IsSyndicated = 1
				AND COD.IsPrivateLabel = 0
				AND CSD.IsPrivateLabel = 0
				THEN CSD.FunderId
			WHEN (COD.OriginationSource = @OriginationChannel_Direct)
				AND C.IsSyndicated = 1
				AND CSD.IsPrivateLabel = 0
				THEN CSD.FunderId
			ELSE C.LegalEntityId
		END OriginationSourceId,
		@CreatedById,
		GETDATE()
	FROM CTE_ContractsInUse C
	LEFT JOIN CTE_UpdatedContractOriginationDetails COD ON C.ContractId = COD.ContractId
		AND COD.OriginationServicings = 1
	LEFT JOIN CTE_UpdateContractSyndicationDetails CSD ON C.ContractId = CSD.ContractId
		AND CSD.SyndicationServicings = 1;
END

GO
