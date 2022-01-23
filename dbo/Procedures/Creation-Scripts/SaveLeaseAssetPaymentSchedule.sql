SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLeaseAssetPaymentSchedule]
(
 @val [dbo].[LeaseAssetPaymentSchedule] READONLY
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
MERGE [dbo].[LeaseAssetPaymentSchedules] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount_Amount]=S.[Amount_Amount],[Amount_Currency]=S.[Amount_Currency],[AssetId]=S.[AssetId],[InstallationDate]=S.[InstallationDate],[IsActive]=S.[IsActive],[ReceivableAdjustmentAmount_Amount]=S.[ReceivableAdjustmentAmount_Amount],[ReceivableAdjustmentAmount_Currency]=S.[ReceivableAdjustmentAmount_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Amount_Amount],[Amount_Currency],[AssetId],[CreatedById],[CreatedTime],[InstallationDate],[IsActive],[LeasePaymentScheduleId],[ReceivableAdjustmentAmount_Amount],[ReceivableAdjustmentAmount_Currency])
    VALUES (S.[Amount_Amount],S.[Amount_Currency],S.[AssetId],S.[CreatedById],S.[CreatedTime],S.[InstallationDate],S.[IsActive],S.[LeasePaymentScheduleId],S.[ReceivableAdjustmentAmount_Amount],S.[ReceivableAdjustmentAmount_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
