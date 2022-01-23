CREATE TYPE [dbo].[CPUBilling] AS TABLE(
	[BasePassThroughPercent] [decimal](5, 2) NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[OveragePassThroughPercent] [decimal](5, 2) NULL,
	[InvoiceLeadDays] [int] NOT NULL,
	[InvoiceTransitDays] [int] NOT NULL,
	[InvoiceComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsPerfectPay] [bit] NOT NULL,
	[PerfectPayModeAssigned] [bit] NOT NULL,
	[BillToId] [bigint] NULL,
	[RemitToId] [bigint] NULL,
	[PassThroughRemitToId] [bigint] NULL,
	[VendorId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
