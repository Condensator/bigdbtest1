SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[LoadMT940ExtractData]
(
@Tag86Infos MT940Tag86Type READONLY,
@JobStepInstanceId BIGINT,
@UserId BIGINT,
@DecryptionKey NVARCHAR(MAX),
@Filename NVARCHAR(200)
)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	DECLARE @errorMessage NVARCHAR(400)  
	BEGIN TRY

	DECLARE @legalEntityId BIGINT
	DECLARE @EntityType VARCHAR(10) = 'Customer'
	DECLARE @ReceiptType VARCHAR(20) = 'BankStatement'
	DECLARE @CurrentDateTime Datetime = Getdate()
	
	IF OBJECT_ID('MFDdb..#Tag86Infos') IS NULL
	BEGIN
	CREATE TABLE #Tag86Infos
	(
	 DumpId BigInt,
	 EntityId BigInt,
	 PartyNumber NVARCHAR(40)
	)
	END

	IF EXISTS (SELECT 1 FROM @Tag86Infos)
	BEGIN
		INSERT INTO #Tag86Infos
		SELECT * FROM @Tag86Infos
	END

	INSERT INTO CommonExternalReceipt_Extract
	(
	LegalEntityNumber,
	CreatedById,
	CreatedTime,
	EntityType,
	EntityId,
	PartyNumber,
	Currency,
	ReceiptType,
	ReceiptAmount,
	ReceivedDate,
	BankAccount,
	CheckNumber,
	BankName,
	Comment,
	CashType,
	PaymentMode,
	LineOfBusiness,
	InstrumentType,
	BankBranchName,
	CostCenter,
	GUID,
	JobStepInstanceId,
	IsValid,
	BankAccountId,
	LegalEntityId,
	LineOfBusinessId,
	CostCenterId,
	InstrumentTypeId,
	CurrencyId,
	IsApplyCredit,
	ApplyByReceivable,
	IsFullPosting,
    CreateUnallocatedReceipt,
	DumpId
	) 
	SELECT 
	LE.LegalEntityNumber,
	@UserId,
	@CurrentDateTime,
	CASE WHEN tag86.EntityId IS NOT NULL THEN @EntityType ELSE NULL END AS EntityType,
	CASE WHEN tag86.EntityId IS NOT NULL THEN tag86.EntityId ELSE NULL END AS EntityId,
	CASE WHEN tag86.EntityId IS NOT NULL THEN tag86.PartyNumber ELSE NULL END AS PartyNumber,
	MFD.TransactionAmount_Currency,
	@ReceiptType,
	MFD.TransactionAmount_Amount,
	MFD.TransValueDate,
	cast(dbo.Decrypt('varchar',BA.AccountNumber_CT,@DecryptionKey) as nvarchar),
	MFD.TransCustomerReference,
	Bb.BankName,
	MFD.InformationToOwner,
	CT.Type as CashType,
	@ReceiptType as PaymentMode,
	LOB.Code as LineOfBusiness,
	IT.Code as InstrumentType,
	BB.Name as BankBranchName,
	CCC.CostCenter as CostCenter,
	NEWID() as GUID,
	MFD.JobStepInstanceId,
	MFD.IsValid,
	BA.Id as BankAccountId,
	LE.Id as LegalEntityId,
	LOB.Id as LineOfBusinessId,
	CCC.Id as CostCenterId,
	IT.Id as InstrumentTypeId,
	C.Id as CurrencyId,
	1 as IsApplyCredit,
	1 as ApplyByReceivable,
	0 IsFullPosting,
    0 CreateUnallocatedReceipt,
	MFD.ID
	FROM MT940File_Dump MFD 
	LEFT JOIN #Tag86Infos tag86 ON MFD.Id = tag86.DumpId
	LEFT JOIN BankAccounts BA ON MFD.AccountIdentification = BA.IBAN AND BA.IsActive =1
	OR MFD.AccountIdentification = dbo.Decrypt('varchar',BA.AccountNumber_CT,@DecryptionKey)
	LEFT JOIN LegalEntityBankAccounts LEBA ON LEBA.BankAccountId = BA.Id AND LEBA.IsActive =1
	LEFT JOIN LegalEntities LE ON LE.Id = LEBA.LegalEntityId AND LE.Status = 'Active'
	LEFT JOIN 
	(
		SELECT RANK() OVER (PARTITION BY LegalEntityId ORDER BY Id DESC) R, *
		FROM LockBoxDefaultParameterConfigs
		WHERE IsActive = 1
	) LBC ON LBC.R =1  AND LE.Id = LBC.LegalEntityId
	LEFT JOIN CashTypes CT ON LBC.CashTypeId = CT.Id AND CT.IsActive =1
	LEFT JOIN LineofBusinesses LOB ON LBC.LineOfBusinessId = LOB.Id AND LOB.IsActive = 1
	LEFT JOIN InstrumentTypes IT ON LBC.InstrumentTypeId = IT.Id AND IT.IsActive = 1
	LEFT JOIN BankBranches BB ON BA.BankBranchId = BB.Id AND BB.IsActive =1
	LEFT JOIN CostCenterConfigs CCC ON LBC.CostCenterId = CCC.Id AND CCC.IsActive = 1
	LEFT JOIN Currencies C ON MFD.TransactionAmount_Currency = C.Name AND C.IsActive = 1
    WHERE MFD.JobStepInstanceId = @JobStepInstanceId AND MFD.IsValid = 1 AND MFD.Trans_DC = 'Credit'
	AND MFD.Filename = @Filename
	
	END TRY
	BEGIN CATCH
		SELECT ERROR_MESSAGE()
	END CATCH

	DROP TABLE #Tag86Infos
END

GO
