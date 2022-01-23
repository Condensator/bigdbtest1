SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLeaseIncomeRecognitionJobExtract]
(
 @val [dbo].[LeaseIncomeRecognitionJobExtract] READONLY
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
MERGE [dbo].[LeaseIncomeRecognitionJobExtracts] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetCount]=S.[AssetCount],[IsSubmitted]=S.[IsSubmitted],[JobStepInstanceId]=S.[JobStepInstanceId],[LeaseFinanceId]=S.[LeaseFinanceId],[PostDate]=S.[PostDate],[ProcessThroughDate]=S.[ProcessThroughDate],[TaskChunkServiceInstanceId]=S.[TaskChunkServiceInstanceId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetCount],[CreatedById],[CreatedTime],[IsSubmitted],[JobStepInstanceId],[LeaseFinanceId],[PostDate],[ProcessThroughDate],[TaskChunkServiceInstanceId])
    VALUES (S.[AssetCount],S.[CreatedById],S.[CreatedTime],S.[IsSubmitted],S.[JobStepInstanceId],S.[LeaseFinanceId],S.[PostDate],S.[ProcessThroughDate],S.[TaskChunkServiceInstanceId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
