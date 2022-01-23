CREATE TYPE [dbo].[CPUOverageReceivableTierInfo] AS TABLE(
	[BeginUnit] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EndUnit] [int] NOT NULL,
	[Rate] [decimal](14, 9) NOT NULL,
	[CPUOverageReceivableInfoId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
