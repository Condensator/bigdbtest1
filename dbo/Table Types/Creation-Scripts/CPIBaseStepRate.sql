CREATE TYPE [dbo].[CPIBaseStepRate] AS TABLE(
	[Rate] [decimal](8, 4) NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StepPeriod] [int] NULL,
	[CPIReceivableDetailId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
