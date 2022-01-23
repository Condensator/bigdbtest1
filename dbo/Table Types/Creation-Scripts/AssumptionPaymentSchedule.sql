CREATE TYPE [dbo].[AssumptionPaymentSchedule] AS TABLE(
	[VATAmount_Amount] [decimal](16, 2) NOT NULL,
	[VATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Calculate] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CustomerNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CustomerName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[LeasePaymentScheduleId] [bigint] NOT NULL,
	[AssumptionId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
