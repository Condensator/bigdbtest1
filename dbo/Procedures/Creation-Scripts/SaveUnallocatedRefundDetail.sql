SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveUnallocatedRefundDetail]
(
 @val [dbo].[UnallocatedRefundDetail] READONLY
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
MERGE [dbo].[UnallocatedRefundDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AmountToBeCleared_Amount]=S.[AmountToBeCleared_Amount],[AmountToBeCleared_Currency]=S.[AmountToBeCleared_Currency],[Description]=S.[Description],[ReceiptAllocationId]=S.[ReceiptAllocationId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AmountToBeCleared_Amount],[AmountToBeCleared_Currency],[CreatedById],[CreatedTime],[Description],[ReceiptAllocationId],[UnallocatedRefundId])
    VALUES (S.[AmountToBeCleared_Amount],S.[AmountToBeCleared_Currency],S.[CreatedById],S.[CreatedTime],S.[Description],S.[ReceiptAllocationId],S.[UnallocatedRefundId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
