SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TreasuryPayableDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ReceivableOffsetAmount_Amount] [decimal](16, 2) NOT NULL,
	[ReceivableOffsetAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PayableId] [bigint] NULL,
	[DisbursementRequestPayableId] [bigint] NULL,
	[TreasuryPayableId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[TreasuryPayableDetails]  WITH CHECK ADD  CONSTRAINT [ETreasuryPayable_TreasuryPayableDetails] FOREIGN KEY([TreasuryPayableId])
REFERENCES [dbo].[TreasuryPayables] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TreasuryPayableDetails] CHECK CONSTRAINT [ETreasuryPayable_TreasuryPayableDetails]
GO
ALTER TABLE [dbo].[TreasuryPayableDetails]  WITH CHECK ADD  CONSTRAINT [ETreasuryPayableDetail_DisbursementRequestPayable] FOREIGN KEY([DisbursementRequestPayableId])
REFERENCES [dbo].[DisbursementRequestPayables] ([Id])
GO
ALTER TABLE [dbo].[TreasuryPayableDetails] CHECK CONSTRAINT [ETreasuryPayableDetail_DisbursementRequestPayable]
GO
ALTER TABLE [dbo].[TreasuryPayableDetails]  WITH CHECK ADD  CONSTRAINT [ETreasuryPayableDetail_Payable] FOREIGN KEY([PayableId])
REFERENCES [dbo].[Payables] ([Id])
GO
ALTER TABLE [dbo].[TreasuryPayableDetails] CHECK CONSTRAINT [ETreasuryPayableDetail_Payable]
GO
