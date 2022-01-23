SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptRentSharingDetails_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceiptId] [bigint] NOT NULL,
	[ReceivableId] [bigint] NOT NULL,
	[RentSharingPercentage] [decimal](16, 2) NOT NULL,
	[VendorId] [bigint] NOT NULL,
	[RemitToId] [bigint] NOT NULL,
	[PayableCodeId] [bigint] NOT NULL,
	[SourceType] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[JobStepInstanceId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PaidPayableAmount] [decimal](16, 2) NULL,
	[WithholdingTaxRate] [decimal](5, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
