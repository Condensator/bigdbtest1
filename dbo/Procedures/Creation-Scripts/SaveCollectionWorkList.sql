SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCollectionWorkList]
(
 @val [dbo].[CollectionWorkList] READONLY
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
MERGE [dbo].[CollectionWorkLists] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssignmentMethod]=S.[AssignmentMethod],[BusinessUnitId]=S.[BusinessUnitId],[CollectionQueueId]=S.[CollectionQueueId],[CurrencyId]=S.[CurrencyId],[CustomerId]=S.[CustomerId],[FlagAsWorked]=S.[FlagAsWorked],[FlagAsWorkedOn]=S.[FlagAsWorkedOn],[NextWorkDate]=S.[NextWorkDate],[PortfolioId]=S.[PortfolioId],[PrimaryCollectorId]=S.[PrimaryCollectorId],[RemitToId]=S.[RemitToId],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssignmentMethod],[BusinessUnitId],[CollectionQueueId],[CreatedById],[CreatedTime],[CurrencyId],[CustomerId],[FlagAsWorked],[FlagAsWorkedOn],[NextWorkDate],[PortfolioId],[PrimaryCollectorId],[RemitToId],[Status])
    VALUES (S.[AssignmentMethod],S.[BusinessUnitId],S.[CollectionQueueId],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[CustomerId],S.[FlagAsWorked],S.[FlagAsWorkedOn],S.[NextWorkDate],S.[PortfolioId],S.[PrimaryCollectorId],S.[RemitToId],S.[Status])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
