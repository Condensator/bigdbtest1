CREATE TYPE [dbo].[CPUOverageTierScheduleDetail] AS TABLE(
	[BeginOverageUnit] [int] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[OverageRate] [decimal](14, 9) NULL,
	[IsActive] [bit] NOT NULL,
	[CPUOverageTierScheduleId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
