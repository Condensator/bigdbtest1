SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssumptionPaymentSchedule]
(
 @val [dbo].[AssumptionPaymentSchedule] READONLY
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
MERGE [dbo].[AssumptionPaymentSchedules] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Calculate]=S.[Calculate],[CustomerName]=S.[CustomerName],[CustomerNumber]=S.[CustomerNumber],[IsActive]=S.[IsActive],[LeasePaymentScheduleId]=S.[LeasePaymentScheduleId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VATAmount_Amount]=S.[VATAmount_Amount],[VATAmount_Currency]=S.[VATAmount_Currency]
WHEN NOT MATCHED THEN
	INSERT ([AssumptionId],[Calculate],[CreatedById],[CreatedTime],[CustomerName],[CustomerNumber],[IsActive],[LeasePaymentScheduleId],[VATAmount_Amount],[VATAmount_Currency])
    VALUES (S.[AssumptionId],S.[Calculate],S.[CreatedById],S.[CreatedTime],S.[CustomerName],S.[CustomerNumber],S.[IsActive],S.[LeasePaymentScheduleId],S.[VATAmount_Amount],S.[VATAmount_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
