CREATE TYPE [dbo].[LockboxFailedRecordInfo] AS TABLE(
	[LockboxLine] [nvarchar](347) COLLATE Latin1_General_CI_AS NULL,
	[ErrorMessages] [nvarchar](2000) COLLATE Latin1_General_CI_AS NULL,
	[FileName] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL
)
GO
