SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[CalculateAmtInTargetCurrency]
(
@SourceCurrencyId INT
,@TargetCurrencyId INT
,@Amount DECIMAL(24,2)
) RETURNS DECIMAL(24,2)
AS
BEGIN
DECLARE @AsOfDate DATETIME
DECLARE @ReturnAmount DECIMAL(24,2)

IF @SourceCurrencyId != @TargetCurrencyId
BEGIN
SELECT TOP(1)@AsOfDate=CurrentBusinessDate FROM BusinessUnits WHERE IsActive=1 AND IsDefault=1
DECLARE @LatestExchangeRate DECIMAL(10,8) = 1
SELECT TOP 1 @LatestExchangeRate = ExchangeRate FROM CurrencyExchangeRates WHERE CurrencyId= @SourceCurrencyId
AND ForeignCurrencyId=@TargetCurrencyId AND IsActive = 1 AND EffectiveDate <= @AsOfDate
ORDER BY EffectiveDate DESC
SET @ReturnAmount = ROUND(@Amount * @LatestExchangeRate,2)
END
ELSE
BEGIN
SET @ReturnAmount = @Amount
END
RETURN @ReturnAmount
END

GO
