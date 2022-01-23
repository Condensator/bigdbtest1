SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveTiedContractPaymentDetail]
(
 @val [dbo].[TiedContractPaymentDetail] READONLY
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
MERGE [dbo].[TiedContractPaymentDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Balance_Amount]=S.[Balance_Amount],[Balance_Currency]=S.[Balance_Currency],[ContractId]=S.[ContractId],[IsActive]=S.[IsActive],[PaymentScheduleId]=S.[PaymentScheduleId],[SharedAmount_Amount]=S.[SharedAmount_Amount],[SharedAmount_Currency]=S.[SharedAmount_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Balance_Amount],[Balance_Currency],[ContractId],[CreatedById],[CreatedTime],[DiscountingRepaymentScheduleId],[IsActive],[PaymentScheduleId],[SharedAmount_Amount],[SharedAmount_Currency])
    VALUES (S.[Balance_Amount],S.[Balance_Currency],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[DiscountingRepaymentScheduleId],S.[IsActive],S.[PaymentScheduleId],S.[SharedAmount_Amount],S.[SharedAmount_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
