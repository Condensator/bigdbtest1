SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditProfileServicingDetails](
	[Id] [bigint] NOT NULL,
	[IsLessorServiced] [bit] NOT NULL,
	[IsLessorCollected] [bit] NOT NULL,
	[IsPerfectPay] [bit] NOT NULL,
	[IsPrivateLabel] [bit] NOT NULL,
	[IsNonNotification] [bit] NOT NULL,
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
ALTER TABLE [dbo].[CreditProfileServicingDetails]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_CreditProfileServicingDetail] FOREIGN KEY([Id])
REFERENCES [dbo].[CreditProfiles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditProfileServicingDetails] CHECK CONSTRAINT [ECreditProfile_CreditProfileServicingDetail]
GO
