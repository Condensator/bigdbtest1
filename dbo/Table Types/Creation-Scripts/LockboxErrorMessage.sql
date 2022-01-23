CREATE TYPE [dbo].[LockboxErrorMessage] AS TABLE(
	[ErrorCode] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[ErrorMessage] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	UNIQUE NONCLUSTERED 
(
	[ErrorCode] ASC
)WITH (IGNORE_DUP_KEY = OFF)
)
GO
