SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeaseBlendedItemVATInfoes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[VATAmount_Amount] [decimal](16, 2) NOT NULL,
	[VATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DueDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[BlendedItemId] [bigint] NOT NULL,
	[LeaseBlendedItemId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeaseBlendedItemVATInfoes]  WITH CHECK ADD  CONSTRAINT [ELeaseBlendedItem_LeaseBlendedItemVATInfoes] FOREIGN KEY([LeaseBlendedItemId])
REFERENCES [dbo].[LeaseBlendedItems] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LeaseBlendedItemVATInfoes] CHECK CONSTRAINT [ELeaseBlendedItem_LeaseBlendedItemVATInfoes]
GO
ALTER TABLE [dbo].[LeaseBlendedItemVATInfoes]  WITH CHECK ADD  CONSTRAINT [ELeaseBlendedItemVATInfo_BlendedItem] FOREIGN KEY([BlendedItemId])
REFERENCES [dbo].[BlendedItems] ([Id])
GO
ALTER TABLE [dbo].[LeaseBlendedItemVATInfoes] CHECK CONSTRAINT [ELeaseBlendedItemVATInfo_BlendedItem]
GO
