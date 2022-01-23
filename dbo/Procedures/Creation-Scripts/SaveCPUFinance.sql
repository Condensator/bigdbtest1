SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCPUFinance]
(
 @val [dbo].[CPUFinance] READONLY
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
MERGE [dbo].[CPUFinances] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BasePaymentFrequency]=S.[BasePaymentFrequency],[CommencementDate]=S.[CommencementDate],[CurrencyId]=S.[CurrencyId],[CustomerId]=S.[CustomerId],[DueDay]=S.[DueDay],[IsAdvanceBilling]=S.[IsAdvanceBilling],[LegalEntityId]=S.[LegalEntityId],[PayoffDate]=S.[PayoffDate],[ReadDay]=S.[ReadDay],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BasePaymentFrequency],[CommencementDate],[CreatedById],[CreatedTime],[CurrencyId],[CustomerId],[DueDay],[IsAdvanceBilling],[LegalEntityId],[PayoffDate],[ReadDay])
    VALUES (S.[BasePaymentFrequency],S.[CommencementDate],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[CustomerId],S.[DueDay],S.[IsAdvanceBilling],S.[LegalEntityId],S.[PayoffDate],S.[ReadDay])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
