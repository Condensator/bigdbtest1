CREATE TYPE [dbo].[CPUOverageAssessmentDetail] AS TABLE(
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MeterReadingId] [bigint] NOT NULL,
	[ReceivableId] [bigint] NULL,
	[CPUOverageAssessmentId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
