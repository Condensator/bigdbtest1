SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ArchiveTransactionTracker]
AS
SELECT T.Id into #Del FROM [TransactionTrackerLogs] T WHERE T.[IsActive] = 0

INSERT INTO [TransactionTrackerLogHistories](
		[TrackerKey]
		,[TrackerEntryToken]
		,[LockedById]
		,[IsActive]
		,[CreatedById]
		,[CreatedTime]
		,[UpdatedById]
		,[UpdatedTime]
)
SELECT	[TrackerKey]
		,[TrackerEntryToken]
		,[LockedById]
		,[IsActive]
		,[CreatedById]
		,[CreatedTime]
		,[UpdatedById]
		,[UpdatedTime]
FROM [TransactionTrackerLogs] TE JOIN #Del d ON TE.Id = d.Id 

if(@@RowCount > 0)
BEGIN
	delete TE from [TransactionTrackerLogs] TE JOIN #Del d ON TE.Id = d.Id
	/*ALTER INDEX ALL ON TransactionTrackerLogs rebuild WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON);*/
END

GO
