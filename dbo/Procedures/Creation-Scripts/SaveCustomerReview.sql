SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCustomerReview]
(
 @val [dbo].[CustomerReview] READONLY
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
MERGE [dbo].[CustomerReviews] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActualReviewDate]=S.[ActualReviewDate],[CustomerId]=S.[CustomerId],[FinancialDate]=S.[FinancialDate],[FinancialDocumentExpectedDate]=S.[FinancialDocumentExpectedDate],[FinancialDocumentReceivedDate]=S.[FinancialDocumentReceivedDate],[IsDummy]=S.[IsDummy],[IsFinancialDocumentRequired]=S.[IsFinancialDocumentRequired],[IsManualReviewRequired]=S.[IsManualReviewRequired],[LastCustomerReviewId]=S.[LastCustomerReviewId],[ManualReviewReason]=S.[ManualReviewReason],[ReviewComments]=S.[ReviewComments],[ReviewType]=S.[ReviewType],[ScheduledDate]=S.[ScheduledDate],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ActualReviewDate],[CreatedById],[CreatedTime],[CustomerId],[FinancialDate],[FinancialDocumentExpectedDate],[FinancialDocumentReceivedDate],[IsDummy],[IsFinancialDocumentRequired],[IsManualReviewRequired],[LastCustomerReviewId],[ManualReviewReason],[ReviewComments],[ReviewType],[ScheduledDate],[Status])
    VALUES (S.[ActualReviewDate],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[FinancialDate],S.[FinancialDocumentExpectedDate],S.[FinancialDocumentReceivedDate],S.[IsDummy],S.[IsFinancialDocumentRequired],S.[IsManualReviewRequired],S.[LastCustomerReviewId],S.[ManualReviewReason],S.[ReviewComments],S.[ReviewType],S.[ScheduledDate],S.[Status])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
