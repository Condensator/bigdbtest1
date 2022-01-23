CREATE TYPE [dbo].[CPUPayoffPaymentSchedule] AS TABLE(
	[PaymentNumber] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StartDate] [date] NOT NULL,
	[EndDate] [date] NOT NULL,
	[DueDate] [date] NOT NULL,
	[BaseAmount_Amount] [decimal](16, 2) NOT NULL,
	[BaseAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BaseUnits] [int] NULL,
	[PaymentType] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CPUPayoffScheduleId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
