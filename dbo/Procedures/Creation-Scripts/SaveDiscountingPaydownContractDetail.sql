SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDiscountingPaydownContractDetail]
(
 @val [dbo].[DiscountingPaydownContractDetail] READONLY
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
MERGE [dbo].[DiscountingPaydownContractDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccountResidualBalanceToGainLoss]=S.[AccountResidualBalanceToGainLoss],[BookedResidual_Amount]=S.[BookedResidual_Amount],[BookedResidual_Currency]=S.[BookedResidual_Currency],[DiscountingContractId]=S.[DiscountingContractId],[IsActive]=S.[IsActive],[Release]=S.[Release],[ResidualGainLoss_Amount]=S.[ResidualGainLoss_Amount],[ResidualGainLoss_Currency]=S.[ResidualGainLoss_Currency],[ResidualPayable_Amount]=S.[ResidualPayable_Amount],[ResidualPayable_Currency]=S.[ResidualPayable_Currency],[TotalPaymentSold_Amount]=S.[TotalPaymentSold_Amount],[TotalPaymentSold_Currency]=S.[TotalPaymentSold_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AccountResidualBalanceToGainLoss],[BookedResidual_Amount],[BookedResidual_Currency],[CreatedById],[CreatedTime],[DiscountingContractId],[DiscountingPaydownId],[IsActive],[Release],[ResidualGainLoss_Amount],[ResidualGainLoss_Currency],[ResidualPayable_Amount],[ResidualPayable_Currency],[TotalPaymentSold_Amount],[TotalPaymentSold_Currency])
    VALUES (S.[AccountResidualBalanceToGainLoss],S.[BookedResidual_Amount],S.[BookedResidual_Currency],S.[CreatedById],S.[CreatedTime],S.[DiscountingContractId],S.[DiscountingPaydownId],S.[IsActive],S.[Release],S.[ResidualGainLoss_Amount],S.[ResidualGainLoss_Currency],S.[ResidualPayable_Amount],S.[ResidualPayable_Currency],S.[TotalPaymentSold_Amount],S.[TotalPaymentSold_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
