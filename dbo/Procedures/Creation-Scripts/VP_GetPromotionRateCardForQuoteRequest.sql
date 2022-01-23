SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[VP_GetPromotionRateCardForQuoteRequest]
(
@PromotionOrProgramId BIGINT,
@IsPromotionCodeSelected BIT,
@QuoteCurrencyId BIGINT = null,
@RateCardFile_Type NVARCHAR(5) OUT,
@RateCardFile_Content VARBINARY(MAX) OUT,
@RateCardFile_Source NVARCHAR(250) OUT,
@RateCardFile_ISO NVARCHAR(10) OUT,
@RateCardDescription NVARCHAR(400) OUT
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT DISTINCT
@RateCardFile_Type = R.RateCardFile_Type,
@RateCardFile_Content = F.Content,
@RateCardFile_Source = R.RateCardFile_Source,
@RateCardFile_ISO = CC.ISO,
@RateCardDescription = RC.[Description]
FROM ProgramRateCards R
INNER JOIN Currencies C ON R.CurrencyId = C.Id
INNER JOIN CurrencyCodes CC ON C.CurrencyCodeId = CC.Id
INNER JOIN FileStores F on F.Guid = dbo.GetContentGuid(R.RateCardFile_Content)
LEFT JOIN ProgramPromotions PP ON PP.ProgramRateCardId = R.Id
LEFT JOIN  Programs P on R.ProgramDetailId = P.ProgramDetailId
LEFT JOIN RateCards RC ON R.RateCardId = RC.Id
WHERE @PromotionOrProgramId = CASE WHEN @IsPromotionCodeSelected = 0
THEN P.Id
ELSE PP.Id
END
AND R.IsDefault IN (CASE WHEN @IsPromotionCodeSelected = 0 THEN 1 ELSE 0 END,1)
AND R.IsActive = 1
AND (@QuoteCurrencyId Is Null Or C.Id = @QuoteCurrencyId)
SELECT
@RateCardFile_Type RateCardFile_Type,
@RateCardFile_Content RateCardFile_Content,
@RateCardFile_Source RateCardFile_Source,
@RateCardFile_ISO RateCardFile_ISO,
@RateCardDescription RateCardDescription 
END

GO
