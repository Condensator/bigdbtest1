CREATE TYPE [dbo].[ErrorCodeInfo] AS TABLE(
	[ErrorCode] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[ErrorCodeMessage] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL
)
GO
