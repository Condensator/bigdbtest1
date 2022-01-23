SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveVertexReceivableCodeDetail_Extract]
(
 @val [dbo].[VertexReceivableCodeDetail_Extract] READONLY
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
MERGE [dbo].[VertexReceivableCodeDetail_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [IsExemptAtReceivableCode]=S.[IsExemptAtReceivableCode],[IsRental]=S.[IsRental],[JobStepInstanceId]=S.[JobStepInstanceId],[ReceivableCodeId]=S.[ReceivableCodeId],[SundryReceivableCode]=S.[SundryReceivableCode],[TaxReceivableName]=S.[TaxReceivableName],[TransactionType]=S.[TransactionType],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[IsExemptAtReceivableCode],[IsRental],[JobStepInstanceId],[ReceivableCodeId],[SundryReceivableCode],[TaxReceivableName],[TransactionType])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[IsExemptAtReceivableCode],S.[IsRental],S.[JobStepInstanceId],S.[ReceivableCodeId],S.[SundryReceivableCode],S.[TaxReceivableName],S.[TransactionType])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
