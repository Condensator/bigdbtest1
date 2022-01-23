SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CreateRecentTransactions]
@recentTransactionParameters RecentTransactionParameters READONLY
AS
BEGIN
INSERT INTO RecentTransactions
( EntityType ,
EntityId ,
TransactionName ,
[Transaction] ,
ReferenceNumber,
ContractId ,
CustomerId ,
Description ,
CreatedById ,
CreatedTime
)
SELECT    EntityType ,
EntityId ,
TransactionName ,
[Transaction] ,
ReferenceNumber,
ContractId ,
CustomerId ,
Description ,
UserId ,
CreatedTime
FROM @recentTransactionParameters
END

GO
