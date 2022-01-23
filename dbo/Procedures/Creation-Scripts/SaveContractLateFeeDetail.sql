SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveContractLateFeeDetail]
(
 @val [dbo].[ContractLateFeeDetail] READONLY
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
MERGE [dbo].[ContractLateFeeDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [DaysLate]=S.[DaysLate],[FlatFee_Amount]=S.[FlatFee_Amount],[FlatFee_Currency]=S.[FlatFee_Currency],[InterestRate]=S.[InterestRate],[IsActive]=S.[IsActive],[PayPercent]=S.[PayPercent],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ContractLateFeeId],[CreatedById],[CreatedTime],[DaysLate],[FlatFee_Amount],[FlatFee_Currency],[InterestRate],[IsActive],[PayPercent])
    VALUES (S.[ContractLateFeeId],S.[CreatedById],S.[CreatedTime],S.[DaysLate],S.[FlatFee_Amount],S.[FlatFee_Currency],S.[InterestRate],S.[IsActive],S.[PayPercent])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
