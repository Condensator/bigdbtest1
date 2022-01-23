SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CreateDiscountingAmortizationSchedules]
(
@AmortizationSchedules DiscountingAmortToCreate READONLY,
@CapitalizedInterests DiscountingCapitalizedInterestsToCreate READONLY,
@CurrencyCode NVARCHAR(3),
@ModificationType NVARCHAR(11),
@ModificationID BIGINT,
@DiscountingFinanceId BIGINT,
@UserId BIGINT,
@ModificationTime DateTimeOffset
)
AS
BEGIN
CREATE TABLE #PersistedAmortSchedule
(
[Key] BIGINT,
[Id] BIGINT
);
MERGE INTO DiscountingAmortizationSchedules
USING @AmortizationSchedules
AS AmortSchedules ON 1=0
WHEN NOT MATCHED THEN
INSERT
(ExpenseDate
,PaymentAmount_Amount
,PaymentAmount_Currency
,BeginNetBookValue_Amount
,BeginNetBookValue_Currency
,EndNetBookValue_Amount
,EndNetBookValue_Currency
,PrincipalRepaid_Amount
,PrincipalRepaid_Currency
,PrincipalAdded_Amount
,PrincipalAdded_Currency
,InterestPayment_Amount
,InterestPayment_Currency
,InterestAccrued_Amount
,InterestAccrued_Currency
,InterestAccrualBalance_Amount
,InterestAccrualBalance_Currency
,InterestRate
,IsSchedule
,IsAccounting
,IsGLPosted
,IsNonAccrual
,CapitalizedInterest_Amount
,CapitalizedInterest_Currency
,PrincipalGainLoss_Amount
,PrincipalGainLoss_Currency
,InterestGainLoss_Amount
,InterestGainLoss_Currency
,ModificationType
,ModificationID
,AdjustmentEntry
,DiscountingFinanceId
,CreatedById
,CreatedTime)
VALUES
(ExpenseDate
,PaymentAmount
,@CurrencyCode
,BeginNetBookValue
,@CurrencyCode
,EndNetBookValue
,@CurrencyCode
,PrincipalRepaid
,@CurrencyCode
,PrincipalAdded
,@CurrencyCode
,InterestPayment
,@CurrencyCode
,InterestAccrued
,@CurrencyCode
,InterestAccrualBalance
,@CurrencyCode
,InterestRate
,IsSchedule
,IsAccounting
,IsGLPosted
,IsNonAccrual
,CapitalizedInterest
,@CurrencyCode
,PrincipalGainLoss
,@CurrencyCode
,InterestGainLoss
,@CurrencyCode
,@ModificationType
,@ModificationID
,AdjustmentEntry
,@DiscountingFinanceId
,@UserId
,@ModificationTime)
OUTPUT AmortSchedules.[Key] AS [Key], INSERTED.Id AS [Id] INTO #PersistedAmortSchedule;
INSERT INTO [dbo].[DiscountingCapitalizedInterests]
([Source]
,[Amount_Amount]
,[Amount_Currency]
,[CapitalizedDate]
,[IsActive]
,[CreatedById]
,[CreatedTime]
,[DiscountingFinanceId])
SELECT
Source
,CapitalizedAmount
,@CurrencyCode
,CapitalizationDate
,1
,@UserId
,@ModificationTime
,@DiscountingFinanceId
FROM @CapitalizedInterests
SELECT * FROM #PersistedAmortSchedule
DROP TABLE #PersistedAmortSchedule
END

GO
