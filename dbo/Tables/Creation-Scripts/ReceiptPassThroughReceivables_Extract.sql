SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptPassThroughReceivables_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivableId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PassThroughPayableDueDate] [date] NULL,
	[TotalPayableAmount] [decimal](16, 2) NULL,
	[PaidPayableAmount] [decimal](16, 2) NULL,
	[VendorId] [bigint] NULL,
	[PayableRemitToId] [bigint] NULL,
	[PayableCodeId] [bigint] NULL,
	[SourceId] [bigint] NULL,
	[SourceTable] [nvarchar](24) COLLATE Latin1_General_CI_AS NULL,
	[PassThroughPercent] [decimal](16, 2) NULL,
	[JobStepInstanceId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[WithholdingTaxRate] [decimal](5, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
