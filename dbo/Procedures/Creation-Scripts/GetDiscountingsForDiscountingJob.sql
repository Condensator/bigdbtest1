SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetDiscountingsForDiscountingJob]
(
@EntityType NVARCHAR(30),
@FilterOption NVARCHAR(10),
@FunderId BIGINT = null,
@DiscountingId BIGINT = null,
@PostDate DATE,
@ProcessThroughDate DATE, 
@JobRunDate DATE,  
@LegalEntityIds LEIdList READONLY,
@ConsiderFiscalCalendar BIT,
@ConsiderFiscalCalendarForPostDate BIT
)
AS
BEGIN
SET NOCOUNT ON;
DECLARE @DiscountingApprovedStatus NVARCHAR(MAX)
SET @DiscountingApprovedStatus='Approved'
DECLARE @DiscountingInactiveStatus NVARCHAR(MAX)
SET @DiscountingInactiveStatus='Inactive'
CREATE TABLE #DiscountingsToProcessPayment(DiscountingId BIGINT);
SELECT
LegalEntities.Id LegalEntityId,
MIN(FiscalEndDate) PostDate,
MIN(CalendarEndDate) ProcessThroughDate
INTO #FiscalCalendarInfo
FROM LegalEntities
JOIN @LegalEntityIds AccessibleLegalEntity ON LegalEntities.Id = AccessibleLegalEntity.LEId
JOIN BusinessCalendars ON LegalEntities.BusinessCalendarId = BusinessCalendars.Id
JOIN FiscalCalendars ON BusinessCalendars.Id = FiscalCalendars.BusinessCalendarId
WHERE FiscalCalendars.FiscalEndDate >= @JobRunDate
GROUP BY LegalEntities.Id
SELECT
Discountings.Id AS DiscountingId
,DiscountingFinanceId = DiscountingFinances.Id
,LegalEntityId = DiscountingFinances.LegalEntityId
,FunderId = DiscountingFinances.FunderId
,LegalEntities.LegalEntityNumber
,SequenceNumber = Discountings.SequenceNumber
,CASE WHEN @ConsiderFiscalCalendarForPostDate = 1 THEN ISNULL(#FiscalCalendarInfo.PostDate,@PostDate) ELSE @PostDate END PostDate
,CASE WHEN @ConsiderFiscalCalendar = 1 THEN ISNULL(#FiscalCalendarInfo.ProcessThroughDate,@ProcessThroughDate) ELSE @ProcessThroughDate END ProcessThroughDate
,GLOpenPeriod.FromDate OpenPeriodStartDate
,GLOpenPeriod.ToDate OpenPeriodEndDate
INTO #DiscountingInfo
FROM Discountings
INNER JOIN DiscountingFinances ON Discountings.Id = DiscountingFinances.DiscountingId
INNER JOIN @LegalEntityIds AccessibleLegalEntity ON DiscountingFinances.LegalEntityId = AccessibleLegalEntity.LEId
INNER JOIN LegalEntities ON AccessibleLegalEntity.LEId = LegalEntities.Id
LEFT JOIN #FiscalCalendarInfo ON AccessibleLegalEntity.LEId = #FiscalCalendarInfo.LegalEntityId
LEFT JOIN (SELECT LE.LEId,OpenPeriod.FromDate,OpenPeriod.ToDate
FROM @LegalEntityIds LE
JOIN GLFinancialOpenPeriods OpenPeriod ON LE.LEId = OpenPeriod.LegalEntityId
WHERE OpenPeriod.IsCurrent = 1)
AS GLOpenPeriod ON LegalEntities.Id = GLOpenPeriod.LEId
WHERE DiscountingFinances.IsCurrent = 1 AND ((DiscountingFinances.ApprovalStatus=@DiscountingApprovedStatus))
AND (@FilterOption = 'All' OR (@EntityType = 'Funder' AND DiscountingFinances.FunderId = @FunderId)
OR (@EntityType = 'Discounting' AND DiscountingFinances.DiscountingId = @DiscountingId))
SELECT
DiscountingId
INTO #DiscountingsForExpenseGL
FROM (SELECT
#DiscountingInfo.DiscountingId
FROM #DiscountingInfo
INNER JOIN DiscountingFinances ON #DiscountingInfo.DiscountingId = DiscountingFinances.DiscountingId
JOIN DiscountingAmortizationSchedules ON DiscountingFinances.Id  = DiscountingAmortizationSchedules.DiscountingFinanceId
WHERE DiscountingAmortizationSchedules.ExpenseDate <= #DiscountingInfo.ProcessThroughDate
AND DiscountingAmortizationSchedules.IsGLPosted = 0
AND DiscountingAmortizationSchedules.IsAccounting=1
AND DiscountingFinances.BookingStatus<>@DiscountingInactiveStatus
GROUP BY #DiscountingInfo.DiscountingId
UNION
SELECT
#DiscountingInfo.DiscountingId
FROM #DiscountingInfo
INNER JOIN DiscountingBlendedItems ON #DiscountingInfo.DiscountingFinanceId = DiscountingBlendedItems.DiscountingFinanceId
INNER JOIN BlendedItems ON DiscountingBlendedItems.BlendedItemId = BlendedItems.Id AND BlendedItems.IsActive=1
INNER JOIN BlendedItemDetails ON BlendedItems.Id = BlendedItemDetails.BlendedItemId AND BlendedItemDetails.IsActive=1
WHERE BlendedItemDetails.DueDate <= #DiscountingInfo.ProcessThroughDate
AND BlendedItemDetails.IsGLPosted = 0
AND (BlendedItems.Occurrence='Recurring' OR BlendedItems.BookRecognitionMode='Accrete')
GROUP BY #DiscountingInfo.DiscountingId)
AS DiscountingAmortsToPostGL
SELECT
#DiscountingInfo.DiscountingId,
DiscountingServicingDetails.Collected,
DiscountingServicingDetails.PerfectPay,
DiscountingServicingDetails.EffectiveDate,
ROW_NUMBER() OVER (PARTITION BY #DiscountingInfo.DiscountingId ORDER BY DiscountingServicingDetails.EffectiveDate) RowNumber
INTO #ServicingDetails
FROM #DiscountingInfo
JOIN DiscountingServicingDetails ON #DiscountingInfo.DiscountingFinanceId = DiscountingServicingDetails.DiscountingFinanceId AND DiscountingServicingDetails.IsActive=1
INSERT INTO #DiscountingsToProcessPayment
SELECT
#DiscountingInfo.DiscountingId
FROM #DiscountingInfo
JOIN DiscountingRepaymentSchedules ON #DiscountingInfo.DiscountingFinanceId = DiscountingRepaymentSchedules.DiscountingFinanceId AND DiscountingRepaymentSchedules.IsActive=1
JOIN #ServicingDetails ServicingDetail ON #DiscountingInfo.DiscountingId = ServicingDetail.DiscountingId
LEFT JOIN #ServicingDetails NextServicingDetail ON ServicingDetail.DiscountingId = NextServicingDetail.DiscountingId AND ServicingDetail.RowNumber + 1 = NextServicingDetail.RowNumber
WHERE
DueDate <= ProcessThroughDate
AND ServicingDetail.EffectiveDate <= DiscountingRepaymentSchedules.DueDate
AND (NextServicingDetail.EffectiveDate IS NULL OR DiscountingRepaymentSchedules.DueDate < NextServicingDetail.EffectiveDate)
AND ServicingDetail.Collected = 0 OR ServicingDetail.PerfectPay = 'Yes'
AND (DiscountingRepaymentSchedules.Principal_Amount <> DiscountingRepaymentSchedules.PrincipalProcessed_Amount
OR DiscountingRepaymentSchedules.Interest_Amount <> DiscountingRepaymentSchedules.InterestProcessed_Amount)
GROUP BY #DiscountingInfo.DiscountingId
SELECT
FilteredDiscountings.DiscountingId
,FilteredDiscountings.DiscountingFinanceId
,FilteredDiscountings.LegalEntityId
,FilteredDiscountings.LegalEntityNumber
,FilteredDiscountings.SequenceNumber
,HasAmortToPostGL = CASE WHEN #DiscountingsForExpenseGL.DiscountingId IS NOT NULL
THEN CAST(1 AS BIT)
ELSE CAST(0 AS BIT)
END
,HasRepaymentToProcess = CASE WHEN #DiscountingsToProcessPayment.DiscountingId IS NOT NULL
THEN CAST(1 AS BIT)
ELSE CAST(0 AS BIT)
END
,FilteredDiscountings.PostDate
,FilteredDiscountings.ProcessThroughDate
,FilteredDiscountings.OpenPeriodStartDate
,FilteredDiscountings.OpenPeriodEndDate
FROM #DiscountingInfo FilteredDiscountings
LEFT JOIN #DiscountingsForExpenseGL ON FilteredDiscountings.DiscountingId = #DiscountingsForExpenseGL.DiscountingId
LEFT JOIN #DiscountingsToProcessPayment ON FilteredDiscountings.DiscountingId = #DiscountingsToProcessPayment.DiscountingId
DROP TABLE #FiscalCalendarInfo
DROP TABLE #DiscountingInfo
DROP TABLE #DiscountingsForExpenseGL
DROP TABLE #DiscountingsToProcessPayment
END

GO
