CREATE TYPE [dbo].[ACHSchedulesToUpdate] AS TABLE(
	[Id] [bigint] NULL,
	[Status] [nvarchar](34) COLLATE Latin1_General_CI_AS NULL,
	[FileGenerationDate] [date] NULL,
	[SettlementDate] [date] NULL,
	[ACHAmount] [decimal](16, 2) NULL,
	[IsStatusOnly] [bit] NULL
)
GO
