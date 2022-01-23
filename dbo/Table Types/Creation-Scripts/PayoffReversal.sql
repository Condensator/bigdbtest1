CREATE TYPE [dbo].[PayoffReversal] AS TABLE(
	[ReversalPostDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReversalComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[InitiateCPIPayoffReversal] [bit] NOT NULL,
	[PayoffId] [bigint] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
