SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveMVRHistory]
(
 @val [dbo].[MVRHistory] READONLY
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
MERGE [dbo].[MVRHistories] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [MVRLastReviewedDate]=S.[MVRLastReviewedDate],[MVRLastRunDate]=S.[MVRLastRunDate],[MVRReviewedBy]=S.[MVRReviewedBy],[MVRStatus]=S.[MVRStatus],[Reason]=S.[Reason],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[DriverId],[MVRLastReviewedDate],[MVRLastRunDate],[MVRReviewedBy],[MVRStatus],[Reason])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[DriverId],S.[MVRLastReviewedDate],S.[MVRLastRunDate],S.[MVRReviewedBy],S.[MVRStatus],S.[Reason])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
