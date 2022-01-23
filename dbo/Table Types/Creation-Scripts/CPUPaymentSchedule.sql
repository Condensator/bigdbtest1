CREATE TYPE [dbo].[CPUPaymentSchedule] AS TABLE(
	[PaymentNumber] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StartDate] [date] NOT NULL,
	[EndDate] [date] NOT NULL,
	[DueDate] [date] NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Units] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[PaymentType] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[CPUBaseStructureId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
