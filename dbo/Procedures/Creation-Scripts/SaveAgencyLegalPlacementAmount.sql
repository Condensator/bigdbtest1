SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAgencyLegalPlacementAmount]
(
 @val [dbo].[AgencyLegalPlacementAmount] READONLY
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
MERGE [dbo].[AgencyLegalPlacementAmounts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Balance_Amount]=S.[Balance_Amount],[Balance_Currency]=S.[Balance_Currency],[CurrencyId]=S.[CurrencyId],[FundsReceived_Amount]=S.[FundsReceived_Amount],[FundsReceived_Currency]=S.[FundsReceived_Currency],[IsActive]=S.[IsActive],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AgencyLegalPlacementId],[Balance_Amount],[Balance_Currency],[CreatedById],[CreatedTime],[CurrencyId],[FundsReceived_Amount],[FundsReceived_Currency],[IsActive])
    VALUES (S.[AgencyLegalPlacementId],S.[Balance_Amount],S.[Balance_Currency],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[FundsReceived_Amount],S.[FundsReceived_Currency],S.[IsActive])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
