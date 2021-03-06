CREATE TYPE [dbo].[DiscountingPaydownRepaymentSchedule] AS TABLE(
	[PaymentNumber] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BeginBalance_Amount] [decimal](16, 2) NOT NULL,
	[BeginBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EndBalance_Amount] [decimal](16, 2) NOT NULL,
	[EndBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DueDate] [date] NULL,
	[EndDate] [date] NULL,
	[StartDate] [date] NULL,
	[Principal_Amount] [decimal](16, 2) NOT NULL,
	[Principal_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Interest_Amount] [decimal](16, 2) NOT NULL,
	[Interest_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[GainLoss_Amount] [decimal](16, 2) NOT NULL,
	[GainLoss_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Calculate] [bit] NOT NULL,
	[PaymentStructure] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[PaymentType] [nvarchar](18) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[AdjustmentEntry] [bit] NOT NULL,
	[DiscountingPaydownId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
