CREATE TYPE [dbo].[BookDepreciationDetails] AS TABLE(
	[BookDepreciationId] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[TerminatedDate] [date] NULL
)
GO
