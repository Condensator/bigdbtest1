SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetUnauthorizedDomainTransactionInstances]
(
	@CurrentUserId INT 
)
AS
BEGIN

IF OBJECT_ID('GetUnauthorizedTransactionInstances') IS NOT NULL
	EXEC GetUnauthorizedTransactionInstances @CurrentUserId;
ELSE
BEGIN
	CREATE TABLE #UnauthorizedTransactionInstances(TransactionInstanceId BIGINT NOT NULL);
	SELECT * FROM #UnauthorizedTransactionInstances;
END

END

GO
