SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePortfolio]
(
 @val [dbo].[Portfolio] READONLY
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
MERGE [dbo].[Portfolios] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActivationDate]=S.[ActivationDate],[CollectionLoadBalancingMethod]=S.[CollectionLoadBalancingMethod],[CollectionWorklistSortingOrder]=S.[CollectionWorklistSortingOrder],[CollectorCapacity]=S.[CollectorCapacity],[DeactivationDate]=S.[DeactivationDate],[Description]=S.[Description],[IsActive]=S.[IsActive],[MasterPortfolioId]=S.[MasterPortfolioId],[Name]=S.[Name],[ShowFollowUpsUpcomingIn]=S.[ShowFollowUpsUpcomingIn],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WorklistHibernationDays]=S.[WorklistHibernationDays]
WHEN NOT MATCHED THEN
	INSERT ([ActivationDate],[CollectionLoadBalancingMethod],[CollectionWorklistSortingOrder],[CollectorCapacity],[CreatedById],[CreatedTime],[DeactivationDate],[Description],[IsActive],[MasterPortfolioId],[Name],[ShowFollowUpsUpcomingIn],[WorklistHibernationDays])
    VALUES (S.[ActivationDate],S.[CollectionLoadBalancingMethod],S.[CollectionWorklistSortingOrder],S.[CollectorCapacity],S.[CreatedById],S.[CreatedTime],S.[DeactivationDate],S.[Description],S.[IsActive],S.[MasterPortfolioId],S.[Name],S.[ShowFollowUpsUpcomingIn],S.[WorklistHibernationDays])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
