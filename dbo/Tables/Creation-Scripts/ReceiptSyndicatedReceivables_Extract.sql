SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptSyndicatedReceivables_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivableId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ReceivableRemitToId] [bigint] NULL,
	[ScrapeFactor] [decimal](16, 2) NULL,
	[ScrapeReceivableCodeId] [bigint] NULL,
	[RentalProceedsPayableCodeId] [bigint] NULL,
	[FunderBillToId] [bigint] NULL,
	[FunderLocationId] [bigint] NULL,
	[FunderRemitToId] [bigint] NULL,
	[TaxRemitFunderId] [bigint] NULL,
	[TaxRemitToId] [bigint] NULL,
	[UtilizedScrapeAmount] [decimal](16, 2) NULL,
	[RentalProceedsPayableCodeName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceReceivableGroupingOption] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[WithholdingTaxRate] [decimal](5, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
