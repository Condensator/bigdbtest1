SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DisbursementRequestPayables](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AmountToPay_Amount] [decimal](16, 2) NOT NULL,
	[AmountToPay_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PayableId] [bigint] NOT NULL,
	[DisbursementRequestId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DisbursementRequestPayables]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequest_DisbursementRequestPayables] FOREIGN KEY([DisbursementRequestId])
REFERENCES [dbo].[DisbursementRequests] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DisbursementRequestPayables] CHECK CONSTRAINT [EDisbursementRequest_DisbursementRequestPayables]
GO
ALTER TABLE [dbo].[DisbursementRequestPayables]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequestPayable_Payable] FOREIGN KEY([PayableId])
REFERENCES [dbo].[Payables] ([Id])
GO
ALTER TABLE [dbo].[DisbursementRequestPayables] CHECK CONSTRAINT [EDisbursementRequestPayable_Payable]
GO
