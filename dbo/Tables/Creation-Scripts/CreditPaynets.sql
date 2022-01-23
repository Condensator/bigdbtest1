SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditPaynets](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PaynetDirectDetailId] [bigint] NULL,
	[CreditProfileId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditPaynets]  WITH CHECK ADD  CONSTRAINT [ECreditPaynet_PaynetDirectDetail] FOREIGN KEY([PaynetDirectDetailId])
REFERENCES [dbo].[PaynetDirectDetails] ([Id])
GO
ALTER TABLE [dbo].[CreditPaynets] CHECK CONSTRAINT [ECreditPaynet_PaynetDirectDetail]
GO
ALTER TABLE [dbo].[CreditPaynets]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_CreditPaynets] FOREIGN KEY([CreditProfileId])
REFERENCES [dbo].[CreditProfiles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditPaynets] CHECK CONSTRAINT [ECreditProfile_CreditPaynets]
GO
