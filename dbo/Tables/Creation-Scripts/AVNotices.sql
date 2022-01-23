SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AVNotices](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AVNoticeNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssessmentNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Type] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LienDate] [date] NULL,
	[TaxYear] [int] NULL,
	[TaxEntity] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceivedDate] [date] NULL,
	[DueDate] [date] NULL,
	[FollowUpDate] [date] NULL,
	[ParcelNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AccountNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TotalAssessed_Amount] [decimal](16, 2) NULL,
	[TotalAssessed_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[RenderedValue_Amount] [decimal](16, 2) NULL,
	[RenderedValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[RenderedValueDifference] [decimal](10, 2) NULL,
	[ApprovalStatus] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[UserBatchID] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Comment] [nvarchar](2000) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StateId] [bigint] NOT NULL,
	[AddressId] [bigint] NULL,
	[PPTAVVendorId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[BusinessUnitId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AVNotices]  WITH CHECK ADD  CONSTRAINT [EAVNotice_Address] FOREIGN KEY([AddressId])
REFERENCES [dbo].[PartyAddresses] ([Id])
GO
ALTER TABLE [dbo].[AVNotices] CHECK CONSTRAINT [EAVNotice_Address]
GO
ALTER TABLE [dbo].[AVNotices]  WITH CHECK ADD  CONSTRAINT [EAVNotice_BusinessUnit] FOREIGN KEY([BusinessUnitId])
REFERENCES [dbo].[BusinessUnits] ([Id])
GO
ALTER TABLE [dbo].[AVNotices] CHECK CONSTRAINT [EAVNotice_BusinessUnit]
GO
ALTER TABLE [dbo].[AVNotices]  WITH CHECK ADD  CONSTRAINT [EAVNotice_PPTAVVendor] FOREIGN KEY([PPTAVVendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[AVNotices] CHECK CONSTRAINT [EAVNotice_PPTAVVendor]
GO
ALTER TABLE [dbo].[AVNotices]  WITH CHECK ADD  CONSTRAINT [EAVNotice_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[AVNotices] CHECK CONSTRAINT [EAVNotice_State]
GO
