SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AppraisalRequests](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AppraisalNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsApplyByAssets] [bit] NOT NULL,
	[Value_Amount] [decimal](16, 2) NULL,
	[Value_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[RequestedDate] [date] NOT NULL,
	[AppraisalDate] [date] NULL,
	[Comment] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[Type] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[OriginationType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CurrencyId] [bigint] NOT NULL,
	[AppraisedById] [bigint] NULL,
	[RequestedById] [bigint] NOT NULL,
	[ThirdPartyAppraiserId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[BusinessUnitId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AppraisalRequests]  WITH CHECK ADD  CONSTRAINT [EAppraisalRequest_AppraisedBy] FOREIGN KEY([AppraisedById])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[AppraisalRequests] CHECK CONSTRAINT [EAppraisalRequest_AppraisedBy]
GO
ALTER TABLE [dbo].[AppraisalRequests]  WITH CHECK ADD  CONSTRAINT [EAppraisalRequest_BusinessUnit] FOREIGN KEY([BusinessUnitId])
REFERENCES [dbo].[BusinessUnits] ([Id])
GO
ALTER TABLE [dbo].[AppraisalRequests] CHECK CONSTRAINT [EAppraisalRequest_BusinessUnit]
GO
ALTER TABLE [dbo].[AppraisalRequests]  WITH CHECK ADD  CONSTRAINT [EAppraisalRequest_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[AppraisalRequests] CHECK CONSTRAINT [EAppraisalRequest_Currency]
GO
ALTER TABLE [dbo].[AppraisalRequests]  WITH CHECK ADD  CONSTRAINT [EAppraisalRequest_RequestedBy] FOREIGN KEY([RequestedById])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[AppraisalRequests] CHECK CONSTRAINT [EAppraisalRequest_RequestedBy]
GO
ALTER TABLE [dbo].[AppraisalRequests]  WITH CHECK ADD  CONSTRAINT [EAppraisalRequest_ThirdPartyAppraiser] FOREIGN KEY([ThirdPartyAppraiserId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[AppraisalRequests] CHECK CONSTRAINT [EAppraisalRequest_ThirdPartyAppraiser]
GO
