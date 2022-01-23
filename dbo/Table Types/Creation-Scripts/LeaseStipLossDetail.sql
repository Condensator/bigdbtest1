CREATE TYPE [dbo].[LeaseStipLossDetail] AS TABLE(
	[Month] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Factor] [decimal](18, 8) NOT NULL,
	[TerminationValue] [decimal](16, 2) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[LeaseFinanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
