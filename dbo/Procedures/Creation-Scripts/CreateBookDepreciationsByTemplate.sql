SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CreateBookDepreciationsByTemplate]
(
@BookDepRecords BookDepByTemplateDetail READONLY,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
	INSERT INTO BookDepreciations
           ([CostBasis_Amount]
		   ,[CostBasis_Currency]
		   ,[Salvage_Amount]
		   ,[Salvage_Currency]
		   ,[BeginDate]
		   ,[EndDate]
		   ,[RemainingLifeInMonths]
		   ,[PerDayDepreciationFactor]
		   ,[IsActive]
		   ,[IsInOTP]
		   ,[CreatedById]
		   ,[CreatedTime]
           ,[AssetId]
		   ,[ContractId]
		   ,[GLTemplateId]
		   ,[InstrumentTypeId]
		   ,[LineofBusinessId]
		   ,[CostCenterId]
           ,[BookDepreciationTemplateId]
		   ,[IsLessorOwned]
		   ,[IsLeaseComponent])
	
	SELECT 
	 bd.CostBasis
	,bd.Currency
	,bd.Salvage
	,bd.Currency
	,bd.BeginDate
	,bd.EndDate
	,bd.RemainingLifeInMonths
	,bd.PerDayDepreciationFactor
	,1
	,bd.IsInOTP
	,@CreatedById
	,@CreatedTime
	,bd.AssetId
	,bd.ContractId
	,bd.GLTemplateId
	,bd.InstrumentTypeId
	,bd.LineOfBusinessId
	,bd.CostCenterId
	,bd.BookDepTemplateId
	,bd.IsLessorOwned
	,bd.IsLeaseComponent

	 FROM @BookDepRecords bd
	

END

GO
