CREATE TYPE [dbo].[CPUScheduleAccounting] AS TABLE(
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BaseFeeReceivableCodeId] [bigint] NULL,
	[OverageFeeReceivableCodeId] [bigint] NULL,
	[BaseFeePayableCodeId] [bigint] NULL,
	[OverageFeePayableCodeId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
