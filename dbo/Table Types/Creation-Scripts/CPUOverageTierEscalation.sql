CREATE TYPE [dbo].[CPUOverageTierEscalation] AS TABLE(
	[EffectiveDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StepPeriod] [int] NOT NULL,
	[EscalationMethod] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[Percentage] [decimal](5, 2) NOT NULL,
	[Rate] [decimal](14, 9) NULL,
	[IsActive] [bit] NOT NULL,
	[OverageDecimalPlaces] [int] NOT NULL,
	[IsCreatedFromBooking] [bit] NOT NULL,
	[CPUOverageStructureId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
