CREATE TYPE [dbo].[RemitToBankDetail] AS TABLE(
	[RemitToId] [bigint] NULL,
	[BankAccountNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[IBAN] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[SWIFTCode] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[TransitCode] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL
)
GO
