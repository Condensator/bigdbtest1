SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveTreasuryPayableDetail]
(
 @val [dbo].[TreasuryPayableDetail] READONLY
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
MERGE [dbo].[TreasuryPayableDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [DisbursementRequestPayableId]=S.[DisbursementRequestPayableId],[IsActive]=S.[IsActive],[PayableId]=S.[PayableId],[ReceivableOffsetAmount_Amount]=S.[ReceivableOffsetAmount_Amount],[ReceivableOffsetAmount_Currency]=S.[ReceivableOffsetAmount_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[DisbursementRequestPayableId],[IsActive],[PayableId],[ReceivableOffsetAmount_Amount],[ReceivableOffsetAmount_Currency],[TreasuryPayableId])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[DisbursementRequestPayableId],S.[IsActive],S.[PayableId],S.[ReceivableOffsetAmount_Amount],S.[ReceivableOffsetAmount_Currency],S.[TreasuryPayableId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
