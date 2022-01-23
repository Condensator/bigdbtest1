SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLeasePreclassificationResult]
(
 @val [dbo].[LeasePreclassificationResult] READONLY
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
MERGE [dbo].[LeasePreclassificationResults] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ContractType]=S.[ContractType],[NinetyPercentTestPresentValue_Amount]=S.[NinetyPercentTestPresentValue_Amount],[NinetyPercentTestPresentValue_Currency]=S.[NinetyPercentTestPresentValue_Currency],[NinetyPercentTestPresentValue5A_Amount]=S.[NinetyPercentTestPresentValue5A_Amount],[NinetyPercentTestPresentValue5A_Currency]=S.[NinetyPercentTestPresentValue5A_Currency],[NinetyPercentTestPresentValue5B_Amount]=S.[NinetyPercentTestPresentValue5B_Amount],[NinetyPercentTestPresentValue5B_Currency]=S.[NinetyPercentTestPresentValue5B_Currency],[PreClassificationYield]=S.[PreClassificationYield],[PreClassificationYield5A]=S.[PreClassificationYield5A],[PreClassificationYield5B]=S.[PreClassificationYield5B],[PreRVINinetyPercentTestPresentValue_Amount]=S.[PreRVINinetyPercentTestPresentValue_Amount],[PreRVINinetyPercentTestPresentValue_Currency]=S.[PreRVINinetyPercentTestPresentValue_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ContractType],[CreatedById],[CreatedTime],[Id],[NinetyPercentTestPresentValue_Amount],[NinetyPercentTestPresentValue_Currency],[NinetyPercentTestPresentValue5A_Amount],[NinetyPercentTestPresentValue5A_Currency],[NinetyPercentTestPresentValue5B_Amount],[NinetyPercentTestPresentValue5B_Currency],[PreClassificationYield],[PreClassificationYield5A],[PreClassificationYield5B],[PreRVINinetyPercentTestPresentValue_Amount],[PreRVINinetyPercentTestPresentValue_Currency])
    VALUES (S.[ContractType],S.[CreatedById],S.[CreatedTime],S.[Id],S.[NinetyPercentTestPresentValue_Amount],S.[NinetyPercentTestPresentValue_Currency],S.[NinetyPercentTestPresentValue5A_Amount],S.[NinetyPercentTestPresentValue5A_Currency],S.[NinetyPercentTestPresentValue5B_Amount],S.[NinetyPercentTestPresentValue5B_Currency],S.[PreClassificationYield],S.[PreClassificationYield5A],S.[PreClassificationYield5B],S.[PreRVINinetyPercentTestPresentValue_Amount],S.[PreRVINinetyPercentTestPresentValue_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
