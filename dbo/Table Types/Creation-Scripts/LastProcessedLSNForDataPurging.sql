CREATE TYPE [dbo].[LastProcessedLSNForDataPurging] AS TABLE(
	[TableName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ProcessedLsn] [binary](10) NULL
)
GO
