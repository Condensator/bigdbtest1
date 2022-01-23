CREATE TYPE [dbo].[ACHUpdateBankAccountInfo] AS TABLE(
	[ACHScheduleExtractId] [bigint] NULL,
	[ErrorMessage] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL
)
GO
