SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SundryDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[BillToId] [bigint] NULL,
	[SundryId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PayableAmount_Amount] [decimal](16, 2) NOT NULL,
	[PayableAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[VATAmount_Amount] [decimal](16, 2) NOT NULL,
	[VATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[SundryDetails]  WITH CHECK ADD  CONSTRAINT [ESundry_SundryDetails] FOREIGN KEY([SundryId])
REFERENCES [dbo].[Sundries] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[SundryDetails] CHECK CONSTRAINT [ESundry_SundryDetails]
GO
ALTER TABLE [dbo].[SundryDetails]  WITH CHECK ADD  CONSTRAINT [ESundryDetail_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[SundryDetails] CHECK CONSTRAINT [ESundryDetail_Asset]
GO
ALTER TABLE [dbo].[SundryDetails]  WITH CHECK ADD  CONSTRAINT [ESundryDetail_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[SundryDetails] CHECK CONSTRAINT [ESundryDetail_BillTo]
GO
