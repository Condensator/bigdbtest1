SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAVNotice]
(
 @val [dbo].[AVNotice] READONLY
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
MERGE [dbo].[AVNotices] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AccountNumber]=S.[AccountNumber],[AddressId]=S.[AddressId],[ApprovalStatus]=S.[ApprovalStatus],[AssessmentNumber]=S.[AssessmentNumber],[AVNoticeNumber]=S.[AVNoticeNumber],[BusinessUnitId]=S.[BusinessUnitId],[Comment]=S.[Comment],[DueDate]=S.[DueDate],[FollowUpDate]=S.[FollowUpDate],[IsActive]=S.[IsActive],[LienDate]=S.[LienDate],[ParcelNumber]=S.[ParcelNumber],[PPTAVVendorId]=S.[PPTAVVendorId],[ReceivedDate]=S.[ReceivedDate],[RenderedValue_Amount]=S.[RenderedValue_Amount],[RenderedValue_Currency]=S.[RenderedValue_Currency],[RenderedValueDifference]=S.[RenderedValueDifference],[StateId]=S.[StateId],[TaxEntity]=S.[TaxEntity],[TaxYear]=S.[TaxYear],[TotalAssessed_Amount]=S.[TotalAssessed_Amount],[TotalAssessed_Currency]=S.[TotalAssessed_Currency],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserBatchID]=S.[UserBatchID]
WHEN NOT MATCHED THEN
	INSERT ([AccountNumber],[AddressId],[ApprovalStatus],[AssessmentNumber],[AVNoticeNumber],[BusinessUnitId],[Comment],[CreatedById],[CreatedTime],[DueDate],[FollowUpDate],[IsActive],[LienDate],[ParcelNumber],[PPTAVVendorId],[ReceivedDate],[RenderedValue_Amount],[RenderedValue_Currency],[RenderedValueDifference],[StateId],[TaxEntity],[TaxYear],[TotalAssessed_Amount],[TotalAssessed_Currency],[Type],[UserBatchID])
    VALUES (S.[AccountNumber],S.[AddressId],S.[ApprovalStatus],S.[AssessmentNumber],S.[AVNoticeNumber],S.[BusinessUnitId],S.[Comment],S.[CreatedById],S.[CreatedTime],S.[DueDate],S.[FollowUpDate],S.[IsActive],S.[LienDate],S.[ParcelNumber],S.[PPTAVVendorId],S.[ReceivedDate],S.[RenderedValue_Amount],S.[RenderedValue_Currency],S.[RenderedValueDifference],S.[StateId],S.[TaxEntity],S.[TaxYear],S.[TotalAssessed_Amount],S.[TotalAssessed_Currency],S.[Type],S.[UserBatchID])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
