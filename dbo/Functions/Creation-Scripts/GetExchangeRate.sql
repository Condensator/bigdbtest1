SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetExchangeRate]
(
@FromCurrency BIGINT,
@ToCurrency BIGINT,
@EffectiveDate DATETIME
)
RETURNS DECIMAL(10,6)
AS
BEGIN
DECLARE @result DECIMAL(10,6)
DECLARE @MaxEffectiveDate DATETIME
SET @result=1.00
SET @MaxEffectiveDate= (SELECT MAX(EffectiveDate) FROM CurrencyExchangeRates WHERE EffectiveDate<@EffectiveDate AND CurrencyId=@ToCurrency AND ForeignCurrencyId=@FromCurrency AND IsActive=1 )
SET @result=(SELECT ExchangeRate FROM CurrencyExchangeRates WHERE CurrencyId=@ToCurrency AND ForeignCurrencyId=@FromCurrency AND EffectiveDate=@MaxEffectiveDate AND IsActive=1)
if @FromCurrency=@ToCurrency
begin
set @result=1.00
end
RETURN ISNULL(@result,1.00)
END

GO
