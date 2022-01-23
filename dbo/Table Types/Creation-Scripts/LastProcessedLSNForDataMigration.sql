CREATE TYPE [dbo].[LastProcessedLSNForDataMigration] AS TABLE(
	[TableName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[ProcessedLsn] [binary](10) NOT NULL
)
GO
