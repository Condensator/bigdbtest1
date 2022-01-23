SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCollectionCustomerStatusHistory]
(
 @val [dbo].[CollectionCustomerStatusHistory] READONLY
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
MERGE [dbo].[CollectionCustomerStatusHistories] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssignedByUserId]=S.[AssignedByUserId],[AssignmentDate]=S.[AssignmentDate],[AssignmentMethod]=S.[AssignmentMethod],[CollectionStatusId]=S.[CollectionStatusId],[CustomerId]=S.[CustomerId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssignedByUserId],[AssignmentDate],[AssignmentMethod],[CollectionStatusId],[CreatedById],[CreatedTime],[CustomerId])
    VALUES (S.[AssignedByUserId],S.[AssignmentDate],S.[AssignmentMethod],S.[CollectionStatusId],S.[CreatedById],S.[CreatedTime],S.[CustomerId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
