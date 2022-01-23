SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveRecurringACHPaymentRequest]
(
 @val [dbo].[RecurringACHPaymentRequest] READONLY
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
MERGE [dbo].[RecurringACHPaymentRequests] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AllReceivableTypes]=S.[AllReceivableTypes],[BankAccountId]=S.[BankAccountId],[ContractId]=S.[ContractId],[CustomerId]=S.[CustomerId],[DayoftheMonth]=S.[DayoftheMonth],[EmailId]=S.[EmailId],[EndDate]=S.[EndDate],[IsActive]=S.[IsActive],[IsEndPaymentOnMaturity]=S.[IsEndPaymentOnMaturity],[PaymentThreshold]=S.[PaymentThreshold],[PaymentThresholdAmount_Amount]=S.[PaymentThresholdAmount_Amount],[PaymentThresholdAmount_Currency]=S.[PaymentThresholdAmount_Currency],[PaymentType]=S.[PaymentType],[RecurringPaymentMethod]=S.[RecurringPaymentMethod],[StartDate]=S.[StartDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AllReceivableTypes],[BankAccountId],[ContractId],[CreatedById],[CreatedTime],[CustomerId],[DayoftheMonth],[EmailId],[EndDate],[IsActive],[IsEndPaymentOnMaturity],[PaymentThreshold],[PaymentThresholdAmount_Amount],[PaymentThresholdAmount_Currency],[PaymentType],[RecurringPaymentMethod],[StartDate])
    VALUES (S.[AllReceivableTypes],S.[BankAccountId],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[DayoftheMonth],S.[EmailId],S.[EndDate],S.[IsActive],S.[IsEndPaymentOnMaturity],S.[PaymentThreshold],S.[PaymentThresholdAmount_Amount],S.[PaymentThresholdAmount_Currency],S.[PaymentType],S.[RecurringPaymentMethod],S.[StartDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
