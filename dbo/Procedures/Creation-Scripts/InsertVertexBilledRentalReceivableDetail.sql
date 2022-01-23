SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- SP to insert billed rental details
CREATE PROCEDURE [dbo].[InsertVertexBilledRentalReceivableDetail]
(
@ExtractedVertexBilledRentalReceivableDetails ExtractedVertexBilledRentalReceivableDetail READONLY,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
INSERT INTO VertexBilledRentalReceivables
(RevenueBilledToDate_Amount, RevenueBilledToDate_Currency, CumulativeAmount_Amount, CumulativeAmount_Currency, IsActive, 
 CreatedById, CreatedTime, ContractId, ReceivableDetailId, AssetId, StateId,AssetSKUId)
SELECT
	 RevenueBilledToDate_Amount 
	,RevenueBilledToDate_Currency
	,CumulativeAmount_Amount 
	,CumulativeAmount_Currency
	,1
	,@CreatedById
	,@CreatedTime
	,ContractId
	,ReceivableDetailId
	,AssetId
	,StateId
	,AssetSKUId
FROM @ExtractedVertexBilledRentalReceivableDetails

END

GO
