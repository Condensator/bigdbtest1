SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePayOffTemplate]
(
 @val [dbo].[PayOffTemplate] READONLY
)
AS
SET NOCOUNT ON;
DECLARE @Output TABLE(
 [Action] NVARCHAR(10) NOT NULL,
 [Id] bigint NOT NULL,
 [Token] int NOT NULL,
 [RowVersion] BIGINT,
 [OldRowVersion] BIGINT
)
MERGE [dbo].[PayOffTemplates] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ApplicableforFloatRateContract]=S.[ApplicableforFloatRateContract],[Description]=S.[Description],[FRRApplicable]=S.[FRRApplicable],[FRROption]=S.[FRROption],[IsActive]=S.[IsActive],[IsApplicableWhenEPOAvailable]=S.[IsApplicableWhenEPOAvailable],[IsEPOApplicable]=S.[IsEPOApplicable],[PayoffTradeUpFeeId]=S.[PayoffTradeUpFeeId],[PortfolioId]=S.[PortfolioId],[ReceivableCodeId]=S.[ReceivableCodeId],[RetainedVendorApplicable]=S.[RetainedVendorApplicable],[TemplateName]=S.[TemplateName],[TemplateType]=S.[TemplateType],[TradeupFeeAmount]=S.[TradeupFeeAmount],[TradeupFeeApplicable]=S.[TradeupFeeApplicable],[TradeupFeeCalculationMethod]=S.[TradeupFeeCalculationMethod],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VendorRetained]=S.[VendorRetained]
WHEN NOT MATCHED THEN
	INSERT ([ApplicableforFloatRateContract],[CreatedById],[CreatedTime],[Description],[FRRApplicable],[FRROption],[IsActive],[IsApplicableWhenEPOAvailable],[IsEPOApplicable],[PayoffTradeUpFeeId],[PortfolioId],[ReceivableCodeId],[RetainedVendorApplicable],[TemplateName],[TemplateType],[TradeupFeeAmount],[TradeupFeeApplicable],[TradeupFeeCalculationMethod],[VendorRetained])
    VALUES (S.[ApplicableforFloatRateContract],S.[CreatedById],S.[CreatedTime],S.[Description],S.[FRRApplicable],S.[FRROption],S.[IsActive],S.[IsApplicableWhenEPOAvailable],S.[IsEPOApplicable],S.[PayoffTradeUpFeeId],S.[PortfolioId],S.[ReceivableCodeId],S.[RetainedVendorApplicable],S.[TemplateName],S.[TemplateType],S.[TradeupFeeAmount],S.[TradeupFeeApplicable],S.[TradeupFeeCalculationMethod],S.[VendorRetained])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
