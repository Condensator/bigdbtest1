CREATE TYPE [dbo].[CPIOverageTier] AS TABLE(
	[BeginOverageUnit] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[OverageRate] [decimal](8, 4) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[LastOverageRateUsed] [decimal](8, 4) NULL,
	[CPIScheduleId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
