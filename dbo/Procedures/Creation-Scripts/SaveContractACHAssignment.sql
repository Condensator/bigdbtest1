SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveContractACHAssignment]
(
 @val [dbo].[ContractACHAssignment] READONLY
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
MERGE [dbo].[ContractACHAssignments] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssignmentNumber]=S.[AssignmentNumber],[BankAccountId]=S.[BankAccountId],[BeginDate]=S.[BeginDate],[DayoftheMonth]=S.[DayoftheMonth],[EndDate]=S.[EndDate],[IsActive]=S.[IsActive],[IsEndPaymentOnMaturity]=S.[IsEndPaymentOnMaturity],[PaymentType]=S.[PaymentType],[ReceivableTypeId]=S.[ReceivableTypeId],[RecurringACHPaymentRequestId]=S.[RecurringACHPaymentRequestId],[RecurringPaymentMethod]=S.[RecurringPaymentMethod],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssignmentNumber],[BankAccountId],[BeginDate],[ContractBillingId],[CreatedById],[CreatedTime],[DayoftheMonth],[EndDate],[IsActive],[IsEndPaymentOnMaturity],[PaymentType],[ReceivableTypeId],[RecurringACHPaymentRequestId],[RecurringPaymentMethod])
    VALUES (S.[AssignmentNumber],S.[BankAccountId],S.[BeginDate],S.[ContractBillingId],S.[CreatedById],S.[CreatedTime],S.[DayoftheMonth],S.[EndDate],S.[IsActive],S.[IsEndPaymentOnMaturity],S.[PaymentType],S.[ReceivableTypeId],S.[RecurringACHPaymentRequestId],S.[RecurringPaymentMethod])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
