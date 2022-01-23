SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveContractHoldingStatusHistory]
(
 @val [dbo].[ContractHoldingStatusHistory] READONLY
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
MERGE [dbo].[ContractHoldingStatusHistories] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [HoldingStatus]=S.[HoldingStatus],[HoldingStatusChange]=S.[HoldingStatusChange],[HoldingStatusComments]=S.[HoldingStatusComments],[HoldingStatusStartDate]=S.[HoldingStatusStartDate],[IsActive]=S.[IsActive],[LastUpdatedByUserId]=S.[LastUpdatedByUserId],[RNI_Amount]=S.[RNI_Amount],[RNI_Currency]=S.[RNI_Currency],[UpdatedByDate]=S.[UpdatedByDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ContractId],[CreatedById],[CreatedTime],[HoldingStatus],[HoldingStatusChange],[HoldingStatusComments],[HoldingStatusStartDate],[IsActive],[LastUpdatedByUserId],[RNI_Amount],[RNI_Currency],[UpdatedByDate])
    VALUES (S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[HoldingStatus],S.[HoldingStatusChange],S.[HoldingStatusComments],S.[HoldingStatusStartDate],S.[IsActive],S.[LastUpdatedByUserId],S.[RNI_Amount],S.[RNI_Currency],S.[UpdatedByDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
