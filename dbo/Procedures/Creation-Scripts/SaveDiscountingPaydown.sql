SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDiscountingPaydown]
(
 @val [dbo].[DiscountingPaydown] READONLY
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
MERGE [dbo].[DiscountingPaydowns] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccountingDate]=S.[AccountingDate],[AccruedInterest_Amount]=S.[AccruedInterest_Amount],[AccruedInterest_Currency]=S.[AccruedInterest_Currency],[Alias]=S.[Alias],[Calculate]=S.[Calculate],[Comment]=S.[Comment],[DiscountingAmendmentId]=S.[DiscountingAmendmentId],[DiscountingFinanceId]=S.[DiscountingFinanceId],[DiscountingRepaymentId]=S.[DiscountingRepaymentId],[DueDate]=S.[DueDate],[GainLoss_Amount]=S.[GainLoss_Amount],[GainLoss_Currency]=S.[GainLoss_Currency],[GoodThroughDate]=S.[GoodThroughDate],[InterestOutstanding_Amount]=S.[InterestOutstanding_Amount],[InterestOutstanding_Currency]=S.[InterestOutstanding_Currency],[InterestPaydown_Amount]=S.[InterestPaydown_Amount],[InterestPaydown_Currency]=S.[InterestPaydown_Currency],[IsPaydownFromDiscounting]=S.[IsPaydownFromDiscounting],[IsRepaymentPricingParametersChanged]=S.[IsRepaymentPricingParametersChanged],[IsRepaymentPricingPerformed]=S.[IsRepaymentPricingPerformed],[IsRepaymentScheduleGenerated]=S.[IsRepaymentScheduleGenerated],[IsRepaymentScheduleParametersChanged]=S.[IsRepaymentScheduleParametersChanged],[IsSystemGenerated]=S.[IsSystemGenerated],[MaturityDate]=S.[MaturityDate],[NumberOfPayments]=S.[NumberOfPayments],[PaydownAmortOption]=S.[PaydownAmortOption],[PaydownAtInception]=S.[PaydownAtInception],[PaydownDate]=S.[PaydownDate],[PaydownGLTemplateId]=S.[PaydownGLTemplateId],[PaydownType]=S.[PaydownType],[PostDate]=S.[PostDate],[PrincipalBalance_Amount]=S.[PrincipalBalance_Amount],[PrincipalBalance_Currency]=S.[PrincipalBalance_Currency],[PrincipalOutstanding_Amount]=S.[PrincipalOutstanding_Amount],[PrincipalOutstanding_Currency]=S.[PrincipalOutstanding_Currency],[PrincipalPaydown_Amount]=S.[PrincipalPaydown_Amount],[PrincipalPaydown_Currency]=S.[PrincipalPaydown_Currency],[QuoteNumber]=S.[QuoteNumber],[RegularPaymentAmount_Amount]=S.[RegularPaymentAmount_Amount],[RegularPaymentAmount_Currency]=S.[RegularPaymentAmount_Currency],[RemitToId]=S.[RemitToId],[Status]=S.[Status],[Term]=S.[Term],[TotalPayments]=S.[TotalPayments],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Yield]=S.[Yield]
WHEN NOT MATCHED THEN
	INSERT ([AccountingDate],[AccruedInterest_Amount],[AccruedInterest_Currency],[Alias],[Calculate],[Comment],[CreatedById],[CreatedTime],[DiscountingAmendmentId],[DiscountingFinanceId],[DiscountingRepaymentId],[DueDate],[GainLoss_Amount],[GainLoss_Currency],[GoodThroughDate],[InterestOutstanding_Amount],[InterestOutstanding_Currency],[InterestPaydown_Amount],[InterestPaydown_Currency],[IsPaydownFromDiscounting],[IsRepaymentPricingParametersChanged],[IsRepaymentPricingPerformed],[IsRepaymentScheduleGenerated],[IsRepaymentScheduleParametersChanged],[IsSystemGenerated],[MaturityDate],[NumberOfPayments],[PaydownAmortOption],[PaydownAtInception],[PaydownDate],[PaydownGLTemplateId],[PaydownType],[PostDate],[PrincipalBalance_Amount],[PrincipalBalance_Currency],[PrincipalOutstanding_Amount],[PrincipalOutstanding_Currency],[PrincipalPaydown_Amount],[PrincipalPaydown_Currency],[QuoteNumber],[RegularPaymentAmount_Amount],[RegularPaymentAmount_Currency],[RemitToId],[Status],[Term],[TotalPayments],[Yield])
    VALUES (S.[AccountingDate],S.[AccruedInterest_Amount],S.[AccruedInterest_Currency],S.[Alias],S.[Calculate],S.[Comment],S.[CreatedById],S.[CreatedTime],S.[DiscountingAmendmentId],S.[DiscountingFinanceId],S.[DiscountingRepaymentId],S.[DueDate],S.[GainLoss_Amount],S.[GainLoss_Currency],S.[GoodThroughDate],S.[InterestOutstanding_Amount],S.[InterestOutstanding_Currency],S.[InterestPaydown_Amount],S.[InterestPaydown_Currency],S.[IsPaydownFromDiscounting],S.[IsRepaymentPricingParametersChanged],S.[IsRepaymentPricingPerformed],S.[IsRepaymentScheduleGenerated],S.[IsRepaymentScheduleParametersChanged],S.[IsSystemGenerated],S.[MaturityDate],S.[NumberOfPayments],S.[PaydownAmortOption],S.[PaydownAtInception],S.[PaydownDate],S.[PaydownGLTemplateId],S.[PaydownType],S.[PostDate],S.[PrincipalBalance_Amount],S.[PrincipalBalance_Currency],S.[PrincipalOutstanding_Amount],S.[PrincipalOutstanding_Currency],S.[PrincipalPaydown_Amount],S.[PrincipalPaydown_Currency],S.[QuoteNumber],S.[RegularPaymentAmount_Amount],S.[RegularPaymentAmount_Currency],S.[RemitToId],S.[Status],S.[Term],S.[TotalPayments],S.[Yield])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
