SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ChangeStatusOfAssetsInLoan]
(
@LoanFinanceId BIGINT,
@UpdateStatus bit,
@CollateralStatus NVARCHAR(50),
@CollateralOnLoanStatus NVARCHAR(50),
@ScrapStatus NVARCHAR(50),
@ContractId bigint,
@CreateHistory bit,
@StatusChange NVARCHAR(50),
@SourceModule NVARCHAR(50),
@AsOfDate DATETIME,
@AcquisitionDate DATETIME,
@AssetHistoryUpdateDetails AssetHistoryContractId readonly,
@AssetIdsForStatusCollateralOnLoan NVARCHAR(MAX),
@AssetIdsForStatusCollateral NVARCHAR(MAX),
@AssetIdsForStatusHistory NVARCHAR(MAX),
@UpdateFinancialType bit,
@RealFinancialType NVARCHAR(50),
@AssetIdsForFinancialTypeReal NVARCHAR(MAX),
@DummyFinancialType NVARCHAR(50),
@AssetIdsForFinancialTypeDummy NVARCHAR(MAX),
@UpdatedById bigint,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON

IF(@UpdateStatus = 1)
BEGIN
UPDATE Assets
SET Status =  @CollateralOnLoanStatus
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM Assets A
JOIN ConvertCSVToBigIntTable(@AssetIdsForStatusCollateralOnLoan,',') csv ON A.Id = csv.Id
UPDATE Assets
SET Status =  @CollateralStatus
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM Assets A
JOIN ConvertCSVToBigIntTable(@AssetIdsForStatusCollateral,',') csv ON A.Id = csv.Id
END
IF(@UpdateFinancialType = 1)
BEGIN
UPDATE Assets
SET FinancialType =@RealFinancialType
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM Assets A
JOIN   ConvertCSVToBigIntTable(@AssetIdsForFinancialTypeReal,',') csv ON A.Id = csv.Id
UPDATE Assets
SET FinancialType =@DummyFinancialType
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM Assets A
JOIN   ConvertCSVToBigIntTable(@AssetIdsForFinancialTypeDummy,',') csv ON A.Id = csv.Id
END
IF(@CreateHistory = 1)
BEGIN

INSERT INTO AssetHistories
(
[AssetId]
,[Reason]
,[AcquisitionDate]
,[AsOfDate]
,[SourceModule]
,[SourceModuleId]
,[Status]
,[FinancialType]
,[CustomerId]
,[ParentAssetId]
,[LegalEntityId]
,[ContractId]
,[CreatedById]
,[CreatedTime]
,[IsReversed]
,[PropertyTaxReportCodeId])
SELECT
A.Id
,@StatusChange
--,@AcquisitionDate
,A.AcquisitionDate
,@AsOfDate
,@SourceModule
,@LoanFinanceId
,A.Status
,A.FinancialType
,A.CustomerId
,A.ParentAssetId
,A.LegalEntityId
,Case When AHC.[ContractId] Is not null Then AHC.[ContractId] Else @ContractId End as 'ContractId'
,@UpdatedById
,@UpdatedTime
,0
,A.PropertyTaxReportCodeId
FROM Assets A
JOIN ConvertCSVToBigIntTable(@AssetIdsForStatusHistory,',') csv ON A.Id = csv.Id
Left JOIN @AssetHistoryUpdateDetails AHC on A.Id  = AHC.[AssetId]
END


END

GO
