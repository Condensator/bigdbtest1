SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AppraisalDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AppraisalValue_Amount] [decimal](16, 2) NULL,
	[AppraisalValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[InPlaceValue_Amount] [decimal](16, 2) NULL,
	[InPlaceValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[InPlaceCurrencyId] [bigint] NOT NULL,
	[ThirdPartyAppraiserId] [bigint] NULL,
	[AppraisalRequestId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AppraisalDetails]  WITH CHECK ADD  CONSTRAINT [EAppraisalDetail_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[AppraisalDetails] CHECK CONSTRAINT [EAppraisalDetail_Asset]
GO
ALTER TABLE [dbo].[AppraisalDetails]  WITH CHECK ADD  CONSTRAINT [EAppraisalDetail_InPlaceCurrency] FOREIGN KEY([InPlaceCurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[AppraisalDetails] CHECK CONSTRAINT [EAppraisalDetail_InPlaceCurrency]
GO
ALTER TABLE [dbo].[AppraisalDetails]  WITH CHECK ADD  CONSTRAINT [EAppraisalDetail_ThirdPartyAppraiser] FOREIGN KEY([ThirdPartyAppraiserId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[AppraisalDetails] CHECK CONSTRAINT [EAppraisalDetail_ThirdPartyAppraiser]
GO
ALTER TABLE [dbo].[AppraisalDetails]  WITH CHECK ADD  CONSTRAINT [EAppraisalRequest_AppraisalDetails] FOREIGN KEY([AppraisalRequestId])
REFERENCES [dbo].[AppraisalRequests] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AppraisalDetails] CHECK CONSTRAINT [EAppraisalRequest_AppraisalDetails]
GO
