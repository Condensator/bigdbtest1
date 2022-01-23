SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePreQuote]
(
 @val [dbo].[PreQuote] READONLY
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
MERGE [dbo].[PreQuotes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BillingComment]=S.[BillingComment],[BillToId]=S.[BillToId],[BusinessUnitId]=S.[BusinessUnitId],[Comment]=S.[Comment],[CurrencyId]=S.[CurrencyId],[CustomerId]=S.[CustomerId],[DueDate]=S.[DueDate],[EffectiveDate]=S.[EffectiveDate],[GoodThroughDate]=S.[GoodThroughDate],[IsFutureQuote]=S.[IsFutureQuote],[IsMultiQuote]=S.[IsMultiQuote],[IsRenewalQuote]=S.[IsRenewalQuote],[LegalEntityId]=S.[LegalEntityId],[PaydownReason]=S.[PaydownReason],[PayoffAssetStatus]=S.[PayoffAssetStatus],[QuoteNumber]=S.[QuoteNumber],[QuoteType]=S.[QuoteType],[RemitToId]=S.[RemitToId],[Status]=S.[Status],[TerminationOptionId]=S.[TerminationOptionId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BillingComment],[BillToId],[BusinessUnitId],[Comment],[CreatedById],[CreatedTime],[CurrencyId],[CustomerId],[DueDate],[EffectiveDate],[GoodThroughDate],[IsFutureQuote],[IsMultiQuote],[IsRenewalQuote],[LegalEntityId],[PaydownReason],[PayoffAssetStatus],[QuoteNumber],[QuoteType],[RemitToId],[Status],[TerminationOptionId])
    VALUES (S.[BillingComment],S.[BillToId],S.[BusinessUnitId],S.[Comment],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[CustomerId],S.[DueDate],S.[EffectiveDate],S.[GoodThroughDate],S.[IsFutureQuote],S.[IsMultiQuote],S.[IsRenewalQuote],S.[LegalEntityId],S.[PaydownReason],S.[PayoffAssetStatus],S.[QuoteNumber],S.[QuoteType],S.[RemitToId],S.[Status],S.[TerminationOptionId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
