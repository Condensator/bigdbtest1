SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCustomerACHAssignment]
(
 @val [dbo].[CustomerACHAssignment] READONLY
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
MERGE [dbo].[CustomerACHAssignments] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssignmentNumber]=S.[AssignmentNumber],[BankAccountId]=S.[BankAccountId],[DayoftheMonth]=S.[DayoftheMonth],[EndDate]=S.[EndDate],[IsActive]=S.[IsActive],[PaymentType]=S.[PaymentType],[ReceivableTypeId]=S.[ReceivableTypeId],[RecurringACHPaymentRequestId]=S.[RecurringACHPaymentRequestId],[RecurringPaymentMethod]=S.[RecurringPaymentMethod],[StartDate]=S.[StartDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssignmentNumber],[BankAccountId],[CreatedById],[CreatedTime],[CustomerId],[DayoftheMonth],[EndDate],[IsActive],[PaymentType],[ReceivableTypeId],[RecurringACHPaymentRequestId],[RecurringPaymentMethod],[StartDate])
    VALUES (S.[AssignmentNumber],S.[BankAccountId],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[DayoftheMonth],S.[EndDate],S.[IsActive],S.[PaymentType],S.[ReceivableTypeId],S.[RecurringACHPaymentRequestId],S.[RecurringPaymentMethod],S.[StartDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
