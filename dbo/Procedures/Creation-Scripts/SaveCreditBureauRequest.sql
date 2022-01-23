SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCreditBureauRequest]
(
 @val [dbo].[CreditBureauRequest] READONLY
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
MERGE [dbo].[CreditBureauRequests] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Active]=S.[Active],[DataReceivedDate]=S.[DataReceivedDate],[DataRequestStatus]=S.[DataRequestStatus],[IsReportToGenerateFromUI]=S.[IsReportToGenerateFromUI],[ManuallyCreated]=S.[ManuallyCreated],[ODDXmlRequest]=S.[ODDXmlRequest],[ODDXmlResponse]=S.[ODDXmlResponse],[RequestedBy]=S.[RequestedBy],[RequestedDate]=S.[RequestedDate],[ReviewStatus]=S.[ReviewStatus],[ScorecardVersion]=S.[ScorecardVersion],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([Active],[CreatedById],[CreatedTime],[CreditProfileId],[DataReceivedDate],[DataRequestStatus],[IsReportToGenerateFromUI],[ManuallyCreated],[ODDXmlRequest],[ODDXmlResponse],[RequestedBy],[RequestedDate],[ReviewStatus],[ScorecardVersion])
    VALUES (S.[Active],S.[CreatedById],S.[CreatedTime],S.[CreditProfileId],S.[DataReceivedDate],S.[DataRequestStatus],S.[IsReportToGenerateFromUI],S.[ManuallyCreated],S.[ODDXmlRequest],S.[ODDXmlResponse],S.[RequestedBy],S.[RequestedDate],S.[ReviewStatus],S.[ScorecardVersion])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
