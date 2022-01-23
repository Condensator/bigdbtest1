SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RentSharingDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Percentage] [decimal](18, 8) NOT NULL,
	[VendorId] [bigint] NOT NULL,
	[PayableCodeId] [bigint] NOT NULL,
	[RemitToId] [bigint] NOT NULL,
	[ReceivableId] [bigint] NOT NULL,
	[SourceType] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[RentSharingDetails]  WITH CHECK ADD  CONSTRAINT [EReceivable_RentSharingDetails] FOREIGN KEY([ReceivableId])
REFERENCES [dbo].[Receivables] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RentSharingDetails] CHECK CONSTRAINT [EReceivable_RentSharingDetails]
GO
ALTER TABLE [dbo].[RentSharingDetails]  WITH CHECK ADD  CONSTRAINT [ERentSharingDetail_PayableCode] FOREIGN KEY([PayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[RentSharingDetails] CHECK CONSTRAINT [ERentSharingDetail_PayableCode]
GO
ALTER TABLE [dbo].[RentSharingDetails]  WITH CHECK ADD  CONSTRAINT [ERentSharingDetail_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[RentSharingDetails] CHECK CONSTRAINT [ERentSharingDetail_RemitTo]
GO
ALTER TABLE [dbo].[RentSharingDetails]  WITH CHECK ADD  CONSTRAINT [ERentSharingDetail_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[RentSharingDetails] CHECK CONSTRAINT [ERentSharingDetail_Vendor]
GO
