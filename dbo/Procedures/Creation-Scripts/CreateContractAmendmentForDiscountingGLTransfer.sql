SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CreateContractAmendmentForDiscountingGLTransfer]
(
@DiscountingGLTransferId BIGINT
,@Alias NVARCHAR(40)
,@AmendmentDate DATETIME
,@Comment NVARCHAR(200)
,@AmendmentAtInception BIT
,@CreatedById BIGINT
,@CreatedTime DATETIMEOFFSET
)
AS
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN
CREATE TABLE #AmendmentTemp
(
CurrentFinanceId BIGINT NOT NULL,
OldFinanceId BIGINT NULL,
CurrencyCode NVARCHAR(3) NOT NULL
);
CREATE TABLE #DiscountingTemp
(
DiscountingId BIGINT,
CurrencyCode NVARCHAR(3) NOT NULL
);
SELECT Discountings.Id DiscountingId,CurrencyCodes.ISO AS CurrencyCode
INTO #DiscountingInfo
FROM DiscountingGLTransferDealDetails
JOIN Discountings ON DiscountingGLTransferDealDetails.DiscountingId = Discountings.Id AND DiscountingGLTransferDealDetails.IsActive=1
JOIN Currencies on Discountings.CurrencyId = Currencies.Id
JOIN CurrencyCodes on Currencies.CurrencyCodeId = CurrencyCodes.Id
WHERE DiscountingGLTransferDealDetails.DiscountingGLTransferId = @DiscountingGLTransferId
WHILE((SELECT COUNT(*) FROM #DiscountingInfo) >= 1)
BEGIN
INSERT INTO #DiscountingTemp
SELECT TOP 500 * FROM #DiscountingInfo
INSERT INTO #AmendmentTemp
SELECT FinanceInfo.CurrentFinanceId, FinanceInfo.OldDiscountingFinanceId, #DiscountingTemp.CurrencyCode
FROM #DiscountingTemp
JOIN (SELECT #DiscountingTemp.DiscountingId,DiscountingFinances.Id AS CurrentFinanceId,MAX(OldDiscountingFinance.Id) OldDiscountingFinanceId
FROM #DiscountingTemp
JOIN DiscountingFinances ON #DiscountingTemp.DiscountingId = DiscountingFinances.DiscountingId AND DiscountingFinances.IsCurrent=1
JOIN DiscountingFinances AS OldDiscountingFinance ON #DiscountingTemp.DiscountingId = OldDiscountingFinance.DiscountingId AND OldDiscountingFinance.IsCurrent=0
GROUP BY #DiscountingTemp.DiscountingId,DiscountingFinances.Id)
AS FinanceInfo ON #DiscountingTemp.DiscountingId = FinanceInfo.DiscountingId
DECLARE @MaxQuoteNumber NVARCHAR(80) = (SELECT ISNULL(MAX(CAST(QuoteNumber as INT)), 0) + 1 from DiscountingAmendments)
INSERT INTO [dbo].[DiscountingAmendments]
([AccountingDate]
,[CreatedById]
,[CreatedTime]
,[AmendmentAtInception]
,[AmendmentDate]
,[AmendmentType]
,[Comment]
,[PostDate]
,[QuoteGoodThroughDate]
,[Alias]
,[QuoteStatus]
,[SourceId]
,[DiscountingFinanceId]
,[DiscountingRepaymentScheduleId]
,[QuoteNumber]
,[AdditionalLoanAmount_Amount]
,[AdditionalLoanAmount_Currency]
,[PreRestructureLoanAmount_Amount]
,[PreRestructureLoanAmount_Currency]
,[PreRestructureYield]
,[RestructureAmortOption]
,[OriginalDiscountingFinanceId])
SELECT
NULL
,@CreatedById
,@CreatedTime
,@AmendmentAtInception
,@AmendmentDate
,'GLTransfer'
,@Comment
, NULL
, NULL
, @Alias
,'Approved'
, NULL
, CurrentFinanceId
, NULL
, ISNULL(@MaxQuoteNumber,1)
, 0.0
, CurrencyCode
, 0.0
,CurrencyCode
,0.0
, '_'
,OldFinanceId
FROM #AmendmentTemp
DELETE FROM #AmendmentTemp
DELETE FROM #DiscountingInfo WHERE DiscountingId IN(SELECT DiscountingId FROM #DiscountingTemp)
DELETE FROM #DiscountingTemp
END
DROP TABLE #AmendmentTemp
DROP TABLE #DiscountingInfo
DROP TABLE #DiscountingTemp
END

GO
